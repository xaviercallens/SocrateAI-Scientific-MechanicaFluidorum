#!/usr/bin/env bash
# Deposit this repository (or just the paper) to Zenodo via the REST API.
#
# WHY THIS EXISTS AND WHY IT DOES NOT PUBLISH BY DEFAULT
# -----------------------------------------------------
# Publishing a Zenodo deposition mints a permanent, public DOI. It cannot be
# deleted or un-published; the only remedy is a new version with a new DOI and a
# tombstone on the old one. That is exactly the class of action this project
# treats as requiring an explicit, separate decision -- so this script creates a
# DRAFT and stops. Review the draft in the browser, then pass --publish (or press
# Publish in the Zenodo UI) as a deliberate second step.
#
# CONVENTIONS INHERITED FROM exploration/gcp/vm_eval.sh
# -----------------------------------------------------
# Every HTTP call has its status code checked separately from its body, every
# failure gets a named state rather than a bare exit, and nothing is inferred
# from a command's silence. That discipline came from three real incidents in
# this project where an unchecked upload and an unchecked grep each reported
# success on a job that had actually failed (LL-29..LL-31).
#
# THE TOKEN IS NEVER PRINTED. It is read from the environment or a file and
# passed to curl by reference. Do not add `set -x` without removing the auth
# header first.
#
# Usage:
#   scripts/zenodo_deposit.sh [--production] [--mode repo|paper] [--publish]
#                             [--token-file PATH] [--ref GIT_REF]
#
#   --production   Target zenodo.org. WITHOUT this flag the script targets
#                  sandbox.zenodo.org, which mints throwaway DOIs and is the
#                  right place to rehearse. Sandbox needs its OWN token from
#                  sandbox.zenodo.org -- a production token 401s there.
#   --mode repo    (default) Archive the whole repository as software: a source
#                  tarball of --ref plus the paper PDF, metadata from .zenodo.json.
#   --mode paper   Deposit the paper alone as a preprint, titled from the paper.
#   --publish      Publish immediately instead of leaving a draft. IRREVERSIBLE.
#   --token-file   Read the token from this file instead of $ZENODO_TOKEN.
#   --ref          Git ref to archive (default: current HEAD's describe, else HEAD).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

HOST="sandbox.zenodo.org"
MODE="repo"
PUBLISH="no"
TOKEN_FILE=""
GIT_REF=""

while [ $# -gt 0 ]; do
  case "$1" in
    --production) HOST="zenodo.org"; shift ;;
    --mode)       MODE="${2:-}"; shift 2 ;;
    --publish)    PUBLISH="yes"; shift ;;
    --token-file) TOKEN_FILE="${2:-}"; shift 2 ;;
    --ref)        GIT_REF="${2:-}"; shift 2 ;;
    -h|--help)    sed -n '1,40p' "$0"; exit 0 ;;
    *) echo "FAILED_ARGS: unknown argument '$1'" >&2; exit 2 ;;
  esac
done

case "$MODE" in
  repo|paper) ;;
  *) echo "FAILED_ARGS: --mode must be 'repo' or 'paper', got '$MODE'" >&2; exit 2 ;;
esac

API="https://${HOST}/api"

# ---- token, by reference only -------------------------------------------------
if [ -n "$TOKEN_FILE" ]; then
  [ -r "$TOKEN_FILE" ] || { echo "FAILED_TOKEN: cannot read token file '$TOKEN_FILE'" >&2; exit 3; }
  ZENODO_TOKEN="$(tr -d '[:space:]' < "$TOKEN_FILE")"
fi
if [ -z "${ZENODO_TOKEN:-}" ]; then
  cat >&2 <<'MSG'
FAILED_TOKEN: no token.

  Set it in the environment this script can see, e.g.

      export ZENODO_TOKEN=...        # in ~/.profile, then start a new shell
      scripts/zenodo_deposit.sh

  or keep it in a file and point at it:

      install -m 600 /dev/null ~/.config/zenodo/token
      # paste the token into that file, then
      scripts/zenodo_deposit.sh --token-file ~/.config/zenodo/token

  Note: an export typed at an interactive prompt is NOT inherited by other
  shells (and Ubuntu's ~/.bashrc returns early for non-interactive shells, so
  putting it there does not help either). ~/.profile or a token file both work.
MSG
  exit 3
fi
AUTH="Authorization: Bearer ${ZENODO_TOKEN}"

# ---- preflight ----------------------------------------------------------------
PAPER="docs/paper/exact_triad_structure.pdf"
[ -f "$PAPER" ] || { echo "FAILED_PREFLIGHT: missing $PAPER (build it first)" >&2; exit 4; }
[ -f ".zenodo.json" ] || { echo "FAILED_PREFLIGHT: missing .zenodo.json" >&2; exit 4; }
jq -e . .zenodo.json >/dev/null 2>&1 || { echo "FAILED_PREFLIGHT: .zenodo.json is not valid JSON" >&2; exit 4; }

if [ -z "$GIT_REF" ]; then
  GIT_REF="$(git describe --tags --exact-match 2>/dev/null || echo HEAD)"
fi
git rev-parse --verify --quiet "$GIT_REF" >/dev/null \
  || { echo "FAILED_PREFLIGHT: '$GIT_REF' is not a valid git ref" >&2; exit 4; }

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "WARNING: working tree has uncommitted tracked changes; the archive reflects $GIT_REF, not the tree." >&2
fi

# A deposit is a claim about what the code does. Verify before archiving it.
if [ "$PUBLISH" = "yes" ] && [ "$HOST" = "zenodo.org" ]; then
  echo "== gates must pass before a permanent DOI =="
  ./scripts/verify.sh >/tmp/zenodo_verify.$$ 2>&1 \
    || { echo "FAILED_GATES: scripts/verify.sh did not exit 0; see /tmp/zenodo_verify.$$" >&2; exit 5; }
  echo "   gates PASS"
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ---- metadata -----------------------------------------------------------------
VERSION="$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")"
if [ "$MODE" = "repo" ]; then
  jq --arg v "$VERSION" '{metadata: (. + {version: $v})}' .zenodo.json > "$WORK/meta.json"
else
  PAPER_TITLE="Machine-checked triad identities for the Fourier-Galerkin truncation of the 3-D Navier-Stokes equations, with the vanishing locus of the helical interaction coefficient in closed form"
  jq --arg t "$PAPER_TITLE" --arg v "$VERSION" \
     '{metadata: (. + {title: $t, upload_type: "publication", publication_type: "preprint", version: $v})}' \
     .zenodo.json > "$WORK/meta.json"
fi

# ---- files to upload ----------------------------------------------------------
FILES=("$PAPER")
if [ "$MODE" = "repo" ]; then
  TARBALL="$WORK/MechanicaFluidorum-${VERSION}.tar.gz"
  git archive --format=tar.gz --prefix="MechanicaFluidorum-${VERSION}/" -o "$TARBALL" "$GIT_REF" \
    || { echo "FAILED_ARCHIVE: git archive of '$GIT_REF' failed" >&2; exit 6; }
  FILES+=("$TARBALL")
fi

echo "== Zenodo deposit =="
echo "   host    : $HOST$([ "$HOST" = "sandbox.zenodo.org" ] && echo '  (SANDBOX -- rehearsal, throwaway DOI)')"
echo "   mode    : $MODE"
echo "   ref     : $GIT_REF   version: $VERSION"
echo "   files   : ${FILES[*]}"
echo "   publish : $PUBLISH"

# ---- create the deposition ----------------------------------------------------
code="$(curl -sS -o "$WORK/dep.json" -w '%{http_code}' -X POST "$API/deposit/depositions" \
        -H "$AUTH" -H 'Content-Type: application/json' -d '{}')"
if [ "$code" != "201" ]; then
  echo "FAILED_CREATE: HTTP $code" >&2
  jq -r '.message? // .' "$WORK/dep.json" >&2 2>/dev/null || head -c 400 "$WORK/dep.json" >&2
  [ "$code" = "401" ] && echo "   (401 = wrong token for this host; sandbox and production tokens are separate)" >&2
  exit 7
fi
DEP_ID="$(jq -r '.id' "$WORK/dep.json")"
BUCKET="$(jq -r '.links.bucket' "$WORK/dep.json")"
HTML="$(jq -r '.links.html' "$WORK/dep.json")"
echo "   created deposition $DEP_ID"

# ---- upload each file, checking every status ----------------------------------
for f in "${FILES[@]}"; do
  base="$(basename "$f")"
  code="$(curl -sS -o "$WORK/up.json" -w '%{http_code}' --upload-file "$f" \
          "$BUCKET/$base" -H "$AUTH")"
  if [ "$code" != "200" ] && [ "$code" != "201" ]; then
    echo "FAILED_UPLOAD: '$base' HTTP $code (deposition $DEP_ID left as a draft)" >&2
    jq -r '.message? // .' "$WORK/up.json" >&2 2>/dev/null || head -c 400 "$WORK/up.json" >&2
    exit 8
  fi
  # Trust the server's own record, not the exit code of the upload.
  size="$(jq -r '.size // empty' "$WORK/up.json")"
  local_size="$(stat -c %s "$f")"
  if [ -n "$size" ] && [ "$size" != "$local_size" ]; then
    echo "FAILED_UPLOAD: '$base' size mismatch: local $local_size, server $size" >&2
    exit 8
  fi
  echo "   uploaded $base ($local_size bytes, server confirms $size)"
done

# ---- attach metadata ----------------------------------------------------------
code="$(curl -sS -o "$WORK/meta_resp.json" -w '%{http_code}' -X PUT "$API/deposit/depositions/$DEP_ID" \
        -H "$AUTH" -H 'Content-Type: application/json' -d @"$WORK/meta.json")"
if [ "$code" != "200" ]; then
  echo "FAILED_METADATA: HTTP $code (deposition $DEP_ID left as a draft, files intact)" >&2
  jq -r '.errors? // .message? // .' "$WORK/meta_resp.json" >&2 2>/dev/null || head -c 600 "$WORK/meta_resp.json" >&2
  exit 9
fi
echo "   metadata attached"

# ---- publish only on explicit request -----------------------------------------
if [ "$PUBLISH" != "yes" ]; then
  echo
  echo "DRAFT READY (not published, no DOI minted yet):"
  echo "   $HTML"
  echo "Review it, then publish in the UI or re-run with --publish."
  exit 0
fi

code="$(curl -sS -o "$WORK/pub.json" -w '%{http_code}' -X POST \
        "$API/deposit/depositions/$DEP_ID/actions/publish" -H "$AUTH")"
if [ "$code" != "202" ]; then
  echo "FAILED_PUBLISH: HTTP $code (deposition $DEP_ID remains a draft)" >&2
  jq -r '.message? // .' "$WORK/pub.json" >&2 2>/dev/null || head -c 400 "$WORK/pub.json" >&2
  exit 10
fi
DOI="$(jq -r '.doi // .metadata.prereserve_doi.doi // "unknown"' "$WORK/pub.json")"
echo
echo "PUBLISHED"
echo "   DOI : $DOI"
echo "   URL : $(jq -r '.links.record_html // empty' "$WORK/pub.json")"
