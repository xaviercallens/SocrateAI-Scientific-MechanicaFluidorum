#!/usr/bin/env bash
# TIER C — EXPLORATORY, NO CLAIMS. Laptop-side control of the EXACT EVALUATION job on GCP:
# `--align free --phases-start SEED` at a given M (class set, exact i128 |S| of the seed, exact
# greedy polish). Off the critical path of the M=64 transient; it certifies the exact record.
# Run from the repo root by the owner (gcloud is denied to the agent session).
#
#   bash exploration/gcp/provision_eval.sh preflight M SEED   # auth, quota, bucket, bundle -- creates nothing
#   bash exploration/gcp/provision_eval.sh create    M SEED   # bundle -> bucket -> spot VM (zone/machine fallback)
#   bash exploration/gcp/provision_eval.sh status    [M]      # state, progress, ETA, heartbeat age, cost so far
#   bash exploration/gcp/provision_eval.sh logs      [all]    # serial console (runner lines, or everything)
#   bash exploration/gcp/provision_eval.sh resume             # restart a stopped (preempted) VM
#   bash exploration/gcp/provision_eval.sh fetch     [M]      # pull result + logs, verify the sha256
#   bash exploration/gcp/provision_eval.sh destroy            # delete the VM (bucket and checkpoint kept)
#   bash exploration/gcp/provision_eval.sh bundle    M SEED DIR  # build the job bundle only (used by the local tests)
#
# DESIGN, and the incident behind it (2026-09-15): the first launch failed twice. (1) c2-standard-16
# was refused by the project's C2_CPUS quota of 8 -- now checked in `preflight` before anything is
# created, with machine-type fallback. (2) The VM then TERMINATED within minutes leaving an EMPTY
# bucket: it built from source over ssh and uploaded with `gsutil ... 2>/dev/null`. Now the VM
# needs no ssh and no build (a smoke-tested binary, sha256-verified, with the source as fallback),
# the runner IS the startup script (every boot resumes by itself), all uploads are HTTP-checked,
# and state is visible three independent ways: guest attributes, serial console, bucket.
#
# COST (indicative spot rates, NOT quotes -- printed before creation): c2-standard-8 ~$0.18/h,
# n2-standard-8 ~$0.16/h, n2d-standard-8 ~$0.14/h; --max-run-duration 48h caps any run at
# < $9; the VM powers itself off when done or failed (after a 15-min inspection hold on failure);
# a STOPPED VM bills only its 30 GB pd-balanced disk (~$0.10/day).
set -euo pipefail

PROJECT="gen-lang-client-0625573011"
REGION="us-central1"
ZONES=(us-central1-a us-central1-b us-central1-c us-central1-f)
NAME="${MF_NAME:-mf-eval}"
MACHINES=(c2-standard-8 n2-standard-8 n2d-standard-8)
declare -A QUOTA_METRIC=([c2-standard-8]=C2_CPUS [n2-standard-8]=N2_CPUS [n2d-standard-8]=N2D_CPUS)
declare -A RATE=([c2-standard-8]=0.18 [n2-standard-8]=0.16 [n2d-standard-8]=0.14)
VCPUS=8
IMAGE_FAMILY="ubuntu-2404-lts-amd64"; IMAGE_PROJECT="ubuntu-os-cloud"   # same glibc as the build host
MAX_RUN="48h"
BUCKET="mf-eval-${PROJECT}"
CKPT_EVERY_S="${MF_CKPT_EVERY_S:-120}"
HOLD_S="${MF_HOLD_S:-900}"

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$REPO/exploration/dual_scale_scout_rs"
BIN="$SRC/target/release/dual_scale_scout"
gc() { gcloud --project "$PROJECT" --quiet "$@"; }
say() { echo "== $*"; }
prefix() { echo "m${1:?M}"; }

zone_of() { gc compute instances list --filter="name=$NAME" --format="value(zone.basename())" 2>/dev/null | head -1; }

bundle() {  # M SEED DIR
  local m=$1 seed=$2 dir=$3
  [ -f "$seed" ] || { echo "no seed file $seed"; exit 1; }
  head -1 "$seed" | grep -qx "# scout adversarial phases M=$m" || { echo "seed header is not M=$m: $(head -1 "$seed")"; exit 1; }
  say "building the release binary"
  cargo build --release --quiet --manifest-path "$SRC/Cargo.toml"
  say "local smoke test"
  "$BIN" scout --M 2 --ic adv --align free --steps 0 --every 1 --nu 0.05 --dt 0.001 --lambda -0.05 --E0 144 > /dev/null 2>&1 \
    || { echo "local smoke test FAILED -- not shipping this binary"; exit 1; }
  rm -rf "$dir"; mkdir -p "$dir"
  cp "$BIN" "$dir/dual_scale_scout"
  cp "$seed" "$dir/seed_phases.txt"
  tar -czf "$dir/src.tar.gz" -C "$SRC" Cargo.toml Cargo.lock src
  local rev dirty
  rev=$(git -C "$REPO" rev-parse HEAD)
  dirty=$(git -C "$REPO" status --porcelain -- exploration/dual_scale_scout_rs exploration/gcp | wc -l)
  printf 'GIT_REV=%s\nGIT_DIRTY_FILES=%s\nM=%s\nSEED=%s\nSEED_SHA256=%s\nBUILT=%s\n' \
    "$rev" "$dirty" "$m" "$(basename "$seed")" "$(sha256sum "$seed" | cut -d' ' -f1)" "$(date -u +%FT%TZ)" > "$dir/job.env"
  (cd "$dir" && sha256sum dual_scale_scout seed_phases.txt src.tar.gz job.env > manifest.sha256)
  say "bundle ready in $dir ($(du -sh "$dir" | cut -f1)); git $rev, $dirty uncommitted file(s) in the job's sources"
}

QUOTA_JSON=""
quota_free() {  # metric -> free vCPUs in the region (-1 if the metric is not listed)
  [ -n "$QUOTA_JSON" ] || QUOTA_JSON=$(gc compute regions describe "$REGION" --format=json)
  printf '%s' "$QUOTA_JSON" | python3 -c 'import json, sys
q = {x["metric"]: x for x in json.load(sys.stdin)["quotas"]}
m = sys.argv[1]
print(int(q[m]["limit"] - q[m]["usage"]) if m in q else -1)' "$1"
}

preflight() {  # M SEED -- diagnostics on stderr, the chosen machine type on stdout
  local m=$1 seed=$2
  {
    QUOTA_JSON=$(gc compute regions describe "$REGION" --format=json)   # once; quota_free reads it
    say "gcloud account: $(gcloud config get-value account 2>/dev/null)"
    gc projects describe "$PROJECT" --format="value(projectId)" >/dev/null || { echo "project $PROJECT not accessible"; exit 1; }
    head -1 "$seed" | grep -qx "# scout adversarial phases M=$m" || { echo "seed $seed is not an M=$m phases file"; exit 1; }
    local mt chosen="" free
    for metric in CPUS C2_CPUS N2_CPUS N2D_CPUS; do say "quota $metric free in $REGION: $(quota_free "$metric")"; done
    for mt in "${MACHINES[@]}"; do
      free=$(quota_free "${QUOTA_METRIC[$mt]}")
      if [ "$free" -ge "$VCPUS" ]; then chosen=$mt; break; fi
      say "skip $mt: ${QUOTA_METRIC[$mt]} has $free free, needs $VCPUS"
    done
    [ -n "$chosen" ] || { echo "no machine type in (${MACHINES[*]}) fits the regional quota; request an increase or change REGION"; exit 1; }
    free=$(quota_free CPUS)
    { [ "$free" -lt 0 ] || [ "$free" -ge "$VCPUS" ]; } || { echo "regional CPUS quota has only $free free"; exit 1; }
    gcloud storage buckets describe "gs://$BUCKET" --project "$PROJECT" >/dev/null 2>&1 \
      || { say "creating bucket gs://$BUCKET"; gcloud storage buckets create "gs://$BUCKET" --project "$PROJECT" --location "$REGION"; }
    local p; p=$(prefix "$m")
    if gcloud storage ls "gs://$BUCKET/$p/out/DONE" >/dev/null 2>&1; then
      echo "gs://$BUCKET/$p/out/DONE exists: a result is already there and a new VM would stop at once. Move it aside first."; exit 1
    fi
    if gcloud storage ls "gs://$BUCKET/$p/ckpt/eval.ckpt" >/dev/null 2>&1; then
      say "a checkpoint exists at gs://$BUCKET/$p/ckpt/ -- the new VM will RESUME from it"
    fi
    say "chosen: $chosen at ~\$${RATE[$chosen]}/h spot (indicative, not a quote), cap $MAX_RUN -> worst case ~\$$(python3 -c "print(round(${RATE[$chosen]}*${MAX_RUN%h},2))")"
    echo "$chosen" >&3
  } 3>&1 1>&2
}

case "${1:-}" in
  bundle) bundle "${2:?M}" "${3:?SEED}" "${4:?DIR}" ;;

  preflight) preflight "${2:?M}" "${3:?SEED}" ;;

  create)
    m=${2:?M}; seed=${3:?SEED}; p=$(prefix "$m")
    if [ -n "$(zone_of)" ]; then
      say "instance $NAME already exists in $(zone_of): run 'logs' to keep its diagnosis, then 'destroy', then 'create'"; exit 1
    fi
    machine=$(preflight "$m" "$seed")
    dir=$(mktemp -d)/bundle
    bundle "$m" "$seed" "$dir"
    say "uploading the bundle to gs://$BUCKET/$p/job/"
    gcloud storage cp "$dir"/* "gs://$BUCKET/$p/job/" --project "$PROJECT"
    created=""
    for zone in "${ZONES[@]}"; do
      say "creating $NAME ($machine SPOT) in $zone"
      if err=$(gc compute instances create "$NAME" --zone="$zone" --machine-type="$machine" \
          --provisioning-model=SPOT --instance-termination-action=STOP --max-run-duration="$MAX_RUN" \
          --image-family="$IMAGE_FAMILY" --image-project="$IMAGE_PROJECT" \
          --boot-disk-size=30GB --boot-disk-type=pd-balanced --scopes=storage-rw \
          --metadata="mf-bucket=$BUCKET,mf-prefix=$p,mf-m=$m,mf-ckpt-every-s=$CKPT_EVERY_S,mf-hold-s=$HOLD_S,enable-guest-attributes=TRUE" \
          --metadata-from-file=startup-script="$REPO/exploration/gcp/vm_eval.sh" \
          --labels=purpose=exact-eval,tier=c,m="$m" 2>&1); then
        echo "$err" | grep -v "^WARNING" || true
        created=$zone; break
      fi
      echo "$err" | grep -E "ERROR|-" | head -5
      if echo "$err" | grep -qiE "ZONE_RESOURCE_POOL_EXHAUSTED|does not have enough resources|not available in|UNSUPPORTED_OPERATION|stockout"; then
        say "no capacity in $zone, trying the next zone"; continue
      fi
      say "creation failed for a reason other than zone capacity -- stopping"; exit 1
    done
    [ -n "$created" ] || { say "no zone in $REGION had capacity for $machine"; exit 1; }
    say "created in $created. The VM needs no ssh: the startup script fetches the bundle and runs."
    say "watch it with: bash $0 status $m     (first status within ~2 min of boot)"
    ;;

  status)
    m=${2:-64}; p=$(prefix "$m"); zone=$(zone_of)
    if [ -z "$zone" ]; then say "instance $NAME: ABSENT"; else
      read -r st started mt < <(gc compute instances describe "$NAME" --zone="$zone" \
        --format="value(status,lastStartTimestamp,machineType.basename())")
      say "instance $NAME in $zone: $st ($mt), last start $started"
      if [ "$st" = RUNNING ]; then
        h=$(python3 -c "from datetime import datetime,timezone;s=datetime.fromisoformat('$started');print(round((datetime.now(timezone.utc)-s).total_seconds()/3600,2))")
        say "up $h h since last start, ~\$$(python3 -c "print(round($h*${RATE[$mt]:-0.18},2))") at the indicative rate (not a bill)"
      fi
      attrs=$(mktemp)
      gc compute instances get-guest-attributes "$NAME" --zone="$zone" --query-path=mf/ \
        --format="value(key,value)" > "$attrs" 2>/dev/null || true
      python3 - "$attrs" <<'PY'
import sys, json, datetime
attrs = {}
for line in open(sys.argv[1]):
    if "\t" in line:
        k, v = line.rstrip("\n").split("\t", 1)
        attrs[k] = v
if not attrs:
    print("   (no guest attributes yet -- the runner has not reported; run: logs)")
    sys.exit()
for k in ["status", "detail", "updated", "heartbeat", "load"]:
    if k in attrs:
        print("   %-10s %s" % (k, attrs[k]))
if "heartbeat" in attrs:
    hb = datetime.datetime.fromisoformat(attrs["heartbeat"].replace("Z", "+00:00"))
    age = (datetime.datetime.now(datetime.timezone.utc) - hb).total_seconds()
    print("   heartbeat age %.0f s%s" % (age, "   <-- STALE: the runner is not reporting" if age > 300 else ""))
if "progress" in attrs:
    try:
        p = json.loads(attrs["progress"])
        eta = p.get("eta_phase_s")
        line = "   progress   phase=%s sweep=%s %.2f%% of phase" % (p.get("phase"), p.get("sweep", "-"), 100 * p.get("frac", 0))
        if eta is not None:
            line += ", phase ETA %.2f h" % (eta / 3600)
        line += ", saves=%s, best=%s" % (p.get("saves"), p.get("best", "-"))
        print(line)
    except ValueError:
        print("   progress (unparsed) " + attrs["progress"][:200])
if "last_log" in attrs:
    print("   last_log   " + attrs["last_log"])
PY
      rm -f "$attrs"
    fi
    say "bucket gs://$BUCKET/$p/:"
    gcloud storage ls -l "gs://$BUCKET/$p/out/" "gs://$BUCKET/$p/ckpt/" 2>/dev/null | grep -v "^TOTAL" || echo "   (nothing yet)"
    gcloud storage cat "gs://$BUCKET/$p/out/status.json" 2>/dev/null | sed 's/^/   last status.json: /' || true
    ;;

  logs)
    zone=$(zone_of); [ -n "$zone" ] || { say "instance $NAME absent"; exit 1; }
    mkdir -p "$REPO/exploration/scout_runs/gcp"
    f="$REPO/exploration/scout_runs/gcp/serial-$NAME-$(date -u +%Y%m%dT%H%M%S).log"
    gc compute instances get-serial-port-output "$NAME" --zone="$zone" > "$f" 2>&1 || true
    say "serial console saved to $f ($(wc -l < "$f") lines)"
    if [ "${2:-}" = all ]; then tail -n 150 "$f"; else
      grep -E "MF-EVAL|startup-script|Traceback|panicked|Out of memory|oom-kill|GCEGuestAgent.*(error|Error)" "$f" | tail -n 80 \
        || { say "no runner lines found -- showing the last 80 lines"; tail -n 80 "$f"; }
    fi
    ;;

  resume)
    zone=$(zone_of); [ -n "$zone" ] || { say "instance $NAME absent: use create (a bucket checkpoint is picked up automatically)"; exit 1; }
    st=$(gc compute instances describe "$NAME" --zone="$zone" --format="value(status)")
    [ "$st" = TERMINATED ] || { say "instance is $st, not TERMINATED; nothing to resume"; exit 0; }
    if gc compute instances start "$NAME" --zone="$zone"; then
      say "started; the startup script resumes from the checkpoint by itself"
    else
      say "start failed (often: no spot capacity in $zone). The checkpoint is mirrored in the bucket, so:"
      say "  bash $0 destroy && bash $0 create M SEED     -> a new VM in any zone resumes from it"
    fi
    ;;

  fetch)
    m=${2:-64}; p=$(prefix "$m"); d="$REPO/exploration/scout_runs/gcp/$p"
    mkdir -p "$d"
    gcloud storage cp "gs://$BUCKET/$p/out/*" "$d/" --project "$PROJECT" 2>/dev/null || { say "nothing in gs://$BUCKET/$p/out/ yet"; exit 1; }
    ls -l "$d"
    if [ -f "$d/result.json" ]; then
      say "result:"; python3 -m json.tool "$d/result.json"
      want=$(python3 -c "import json;print(json.load(open('$d/result.json'))['polished_sha256'])")
      got=$(sha256sum "$d/polished_phases.txt" | cut -d' ' -f1)
      [ "$want" = "$got" ] && say "polished_phases.txt sha256 verified" || { say "SHA256 MISMATCH on polished_phases.txt"; exit 1; }
    else
      say "no result.json yet -- latest status:"; cat "$d/status.json" 2>/dev/null || true
    fi
    ;;

  destroy)
    zone=$(zone_of)
    if [ -n "$zone" ]; then gc compute instances delete "$NAME" --zone="$zone"; say "VM and its disk deleted"; else say "(no instance)"; fi
    say "bucket gs://$BUCKET kept (checkpoint + results); 'gcloud storage rm -r gs://$BUCKET/mNN' removes a job's files"
    ;;

  *) sed -n '2,20p' "$0"; exit 2 ;;
esac
