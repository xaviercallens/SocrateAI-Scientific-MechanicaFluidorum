#!/usr/bin/env bash
# TIER C — EXPLORATORY, NO CLAIMS. mf-eval RUNNER for the exact evaluation of a phases file.
#
# This file IS the GCE startup script: it runs as root on EVERY boot -- the first one, and every
# restart after a spot preemption -- so resuming needs no ssh and no human. Everything it needs
# comes from instance metadata (mf-bucket, mf-prefix, mf-m, ...) and a sha256-verified job bundle
# in the bucket, which `provision_eval.sh create` uploads before the VM exists.
#
# Why it looks like this (2026-09-15): the first launch TERMINATED within minutes and left an
# EMPTY bucket and no trace. The previous runner built from source over ssh, uploaded with
# `gsutil ... 2>/dev/null` (silent if gsutil is absent or unauthorised), and had an exit path that
# powered off before uploading. Here:
#   * no build on the critical path: a prebuilt, smoke-tested binary; source build is a fallback;
#   * uploads go through the GCS JSON API with curl and the HTTP code is CHECKED and logged;
#   * every state change is written to the serial console, to guest attributes (readable with
#     `gcloud compute instances get-guest-attributes`, no ssh, no bucket), and to the bucket;
#   * every failure has a named state (FAILED_PREFLIGHT / _INPUT / _BUILD / _RUN / _SCRIPT),
#     uploads diagnostics FIRST, holds for inspection, then powers off;
#   * the scout checkpoints every pass (not just completed sweeps), the checkpoint is mirrored to
#     the bucket, and a fresh VM restores it -- so even a lost disk or a zone change resumes;
#   * a failed attempt is retried from its checkpoint; SIGTERM (preemption) flushes state first.
#
# LOCAL TEST MODE (exploration/gcp/test_runner_local.sh): MF_MODE=local replaces the metadata
# server with MF_* environment variables, the bucket with a directory, and power-off with exit.
set -Eeuo pipefail
umask 022

MODE="${MF_MODE:-gce}"
export HOME="${HOME:-/root}"   # startup scripts may run without HOME; rustup (build fallback) needs it
WORK="${MF_WORK:-/var/lib/mf-eval}"
mkdir -p "$WORK"
cd "$WORK"
LOG="$WORK/runner.log"
MD=http://metadata.google.internal/computeMetadata/v1

ts() { date -u +%FT%TZ; }
log() { local lvl=$1; shift; local line="MF-EVAL $(ts) [$lvl] $*"; echo "$line" >> "$LOG"; echo "$line"; }

md() {  # instance attribute (gce) or MF_<NAME> env var (local); $2 = default
  local name=$1 def=${2:-}
  if [ "$MODE" = gce ]; then
    curl -sf -m 5 -H "Metadata-Flavor: Google" "$MD/instance/attributes/$name" 2>/dev/null || printf '%s' "$def"
  else
    local v="MF_$(printf '%s' "${name#mf-}" | tr 'a-z-' 'A-Z_')"
    printf '%s' "${!v:-$def}"
  fi
}

BUCKET=$(md mf-bucket); PREFIX=$(md mf-prefix); M=$(md mf-m)
CKPT_S=$(md mf-ckpt-every-s 120); HOLD_S=$(md mf-hold-s 900); MAX_ATTEMPTS=$(md mf-max-attempts 4)
HEARTBEAT_S=$(md mf-heartbeat-s 60); UPLOAD_S=$(md mf-upload-s 300); NO_BUILD=$(md mf-no-build 0)
EXTRA_ARGS=$(md mf-extra-args "")

# ---------------------------------------------------------------- storage (checked, retried)
TOKEN=""; TOKEN_EXP=0
refresh_token() {
  [ "$MODE" = gce ] || return 0
  local now j ttl; now=$(date +%s)
  [ -n "$TOKEN" ] && [ "$now" -lt "$TOKEN_EXP" ] && return 0
  j=$(curl -sf -m 10 -H "Metadata-Flavor: Google" "$MD/instance/service-accounts/default/token") || return 1
  TOKEN=$(printf '%s' "$j" | sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  ttl=$(printf '%s' "$j" | sed -n 's/.*"expires_in"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p')
  TOKEN_EXP=$(( now + ${ttl:-300} - 60 ))
  [ -n "$TOKEN" ]
}
urlenc() { printf '%s' "${1//\//%2F}"; }

store_put() {  # local_file object_name -> 0 ok, 1 failed after retries (logged)
  local f=$1 name=$2 code attempt
  if [ "$MODE" = local ]; then
    mkdir -p "$(dirname "$MF_LOCAL_BUCKET/$name")" 2>/dev/null && cp -f "$f" "$MF_LOCAL_BUCKET/$name" 2>/dev/null && return 0
    log WARN "upload $name failed (local bucket not writable)"; return 1
  fi
  for attempt in 1 2 3; do
    code=000
    if refresh_token; then
      code=$(curl -s -m 300 -o "$WORK/.put.out" -w '%{http_code}' -X POST \
        -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/octet-stream" --data-binary @"$f" \
        "https://storage.googleapis.com/upload/storage/v1/b/$BUCKET/o?uploadType=media&name=$(urlenc "$name")") || code=000
      [ "$code" = 200 ] && return 0
    else
      code=no-token
    fi
    log WARN "upload $name failed (attempt $attempt, http=$code): $(head -c 200 "$WORK/.put.out" 2>/dev/null | tr '\n' ' ')"
    sleep $((attempt * 5))
  done
  return 1
}

store_get() {  # object_name local_file -> 0 ok, 2 absent, 1 error (logged)
  local name=$1 f=$2 code attempt
  if [ "$MODE" = local ]; then
    [ -f "$MF_LOCAL_BUCKET/$name" ] || return 2
    cp -f "$MF_LOCAL_BUCKET/$name" "$f"; return 0
  fi
  for attempt in 1 2 3; do
    code=000
    if refresh_token; then
      code=$(curl -s -m 900 -o "$f.part" -w '%{http_code}' -H "Authorization: Bearer $TOKEN" \
        "https://storage.googleapis.com/storage/v1/b/$BUCKET/o/$(urlenc "$name")?alt=media") || code=000
    fi
    if [ "$code" = 200 ]; then mv -f "$f.part" "$f"; return 0; fi
    rm -f "$f.part"
    [ "$code" = 404 ] && return 2
    log WARN "download $name failed (attempt $attempt, http=$code)"
    sleep $((attempt * 5))
  done
  return 1
}

attr() {  # guest attribute mf/<key> (readable without ssh or bucket)
  if [ "$MODE" = local ]; then mkdir -p "$WORK/attrs"; printf '%s' "$2" > "$WORK/attrs/$1"; return 0; fi
  curl -sf -m 5 -X PUT --data "$2" -H "Metadata-Flavor: Google" "$MD/instance/guest-attributes/mf/$1" >/dev/null 2>&1 || true
}

# ---------------------------------------------------------------- status, diagnostics, exit
STATE=BOOT; BOOT_N=0; INSTANCE=local; SCOUT_PID=""
set_status() {
  STATE=$1; shift
  local detail; detail=$(printf '%s' "$*" | tr '"\n' "' " | cut -c1-900)
  log STATUS "$STATE $detail"
  attr status "$STATE"; attr detail "$detail"; attr updated "$(ts)"
  printf '{"state":"%s","detail":"%s","updated":"%s","boot":%s,"instance":"%s","m":"%s"}\n' \
    "$STATE" "$detail" "$(ts)" "$BOOT_N" "$INSTANCE" "$M" > "$WORK/status.json"
  store_put "$WORK/status.json" "$PREFIX/out/status.json" || true
}
snapshot_ckpt() {  # copy before upload: the scout rotates these files at any moment
  local f
  for f in eval.ckpt eval.ckpt.prev; do
    if [ -f "$WORK/$f" ] && cp -f "$WORK/$f" "$WORK/.up.$f" 2>/dev/null; then
      store_put "$WORK/.up.$f" "$PREFIX/ckpt/$f" || true
    fi
  done
  return 0
}
upload_diag() {
  local f
  for f in runner.log scout.log smoke.out progress.json status.json result.json; do
    if [ -f "$WORK/$f" ]; then store_put "$WORK/$f" "$PREFIX/out/$f" || true; fi
  done
  return 0
}
finish() {  # exit code; uploads first, always
  local rc=$1
  # Nothing in the cleanup path may abort it: an `[ -f x ] && ...` returning 1 under `set -e`
  # once exited here BEFORE the power-off (caught by test_runner_local.sh), which on GCE would
  # have left a failed VM running and billing until --max-run-duration.
  trap - ERR
  set +e
  upload_diag; snapshot_ckpt
  if [ "$MODE" = local ]; then exit "$rc"; fi
  if [ "$rc" != 0 ] && [ "$HOLD_S" -gt 0 ]; then
    log INFO "holding ${HOLD_S}s before power-off so the failure can be inspected (serial console / ssh)"
    sleep "$HOLD_S"
  fi
  log INFO "power-off (rc=$rc)"
  shutdown -h now || poweroff || true
  exit "$rc"
}
die() {  # state code message
  local state=$1 code=$2; shift 2
  set_status "$state" "$*"
  finish "$code"
}
on_err() {
  local rc=$? line=$1 cmd=$2
  # `set -E` makes subshells and $(...) inherit this trap. A failure in there must NOT power the
  # machine off from inside the subshell: it surfaces as the parent command's status instead, and
  # the parent's own trap (main shell) reports it with the right line.
  [ "$BASHPID" = "$$" ] || return 0
  set_status FAILED_SCRIPT "runner line $line: $cmd (rc=$rc)"
  finish 14
}
trap 'on_err $LINENO "$BASH_COMMAND"' ERR
on_term() {
  trap - ERR TERM INT
  set +e
  log WARN "SIGTERM/SIGINT (preemption or shutdown): flushing state"
  attr status PREEMPTING
  [ -n "$SCOUT_PID" ] && kill -TERM "$SCOUT_PID" 2>/dev/null || true
  snapshot_ckpt
  store_put "$LOG" "$PREFIX/out/runner.log" || true
  exit 143
}
trap on_term TERM INT

# ---------------------------------------------------------------- boot
BOOT_N=$(( $(cat "$WORK/boots" 2>/dev/null || echo 0) + 1 ))
echo "$BOOT_N" > "$WORK/boots"
if [ "$MODE" = gce ]; then
  INSTANCE=$(curl -sf -m 5 -H "Metadata-Flavor: Google" "$MD/instance/name" || echo unknown)
  ZONE=$(curl -sf -m 5 -H "Metadata-Flavor: Google" "$MD/instance/zone" | sed 's#.*/##' || echo unknown)
  MTYPE=$(curl -sf -m 5 -H "Metadata-Flavor: Google" "$MD/instance/machine-type" | sed 's#.*/##' || echo unknown)
else
  ZONE=local; MTYPE=local
fi
log INFO "boot $BOOT_N instance=$INSTANCE zone=$ZONE machine=$MTYPE nproc=$(nproc) mem=$(awk '/MemTotal/{printf "%.1fG", $2/1048576}' /proc/meminfo) disk_free=$(df -BG --output=avail "$WORK" | tail -1 | tr -d ' ')"

if [ -f "$WORK/DONE" ]; then set_status DONE "already complete (boot $BOOT_N)"; finish 0; fi

# ---------------------------------------------------------------- preflight
set_status PREFLIGHT "boot $BOOT_N"
for t in curl sha256sum tar awk sed timeout; do
  command -v "$t" >/dev/null 2>&1 || die FAILED_PREFLIGHT 10 "missing tool: $t"
done
[ -n "$BUCKET" ] && [ -n "$PREFIX" ] && [ -n "$M" ] || die FAILED_PREFLIGHT 10 "metadata incomplete: mf-bucket='$BUCKET' mf-prefix='$PREFIX' mf-m='$M'"
echo "boot $BOOT_N $(ts) $INSTANCE $ZONE $MTYPE" > "$WORK/boot.txt"
store_put "$WORK/boot.txt" "$PREFIX/out/boot-$BOOT_N.txt" || die FAILED_PREFLIGHT 10 "cannot write to the bucket '$BUCKET' (service-account scope or IAM)"
avail=$(df -BG --output=avail "$WORK" | tail -1 | tr -dc '0-9')
[ "${avail:-0}" -ge 2 ] || die FAILED_PREFLIGHT 10 "only ${avail}G free on $WORK"
rc=0; store_get "$PREFIX/out/DONE" "$WORK/.done.remote" || rc=$?
if [ "$rc" = 0 ]; then touch "$WORK/DONE"; set_status DONE "the bucket already holds a result for $PREFIX; nothing to do"; finish 0; fi

# ---------------------------------------------------------------- job bundle (sha256-verified)
set_status FETCH "bundle gs://$BUCKET/$PREFIX/job/"
mkdir -p "$WORK/job"
for f in manifest.sha256 dual_scale_scout seed_phases.txt src.tar.gz job.env; do
  if [ ! -f "$WORK/job/$f" ]; then
    rc=0; store_get "$PREFIX/job/$f" "$WORK/job/$f" || rc=$?
    [ "$rc" = 0 ] || die FAILED_INPUT 11 "bundle file $f not fetched (rc=$rc; 2 means absent from the bucket)"
  fi
done
if ! (cd "$WORK/job" && sha256sum -c --quiet manifest.sha256) >> "$LOG" 2>&1; then
  bad=$(cd "$WORK/job" && sha256sum -c manifest.sha256 2>&1 | grep -v ': OK$' | tr '\n' ' ' || true)
  rm -rf "$WORK/job"   # refetch next boot rather than trusting a bad copy
  die FAILED_INPUT 11 "sha256 verification failed: $bad"
fi
head -1 "$WORK/job/seed_phases.txt" | grep -qx "# scout adversarial phases M=$M" \
  || die FAILED_INPUT 11 "seed header is '$(head -1 "$WORK/job/seed_phases.txt")', not M=$M"
log INFO "bundle verified: $(grep -h '^GIT' "$WORK/job/job.env" | tr '\n' ' ')"

# ---------------------------------------------------------------- binary (smoke-tested; build is the fallback)
BIN="$WORK/job/dual_scale_scout"
chmod +x "$BIN"
smoke() { timeout 300 "$1" scout --M 2 --ic adv --align free --steps 0 --every 1 --nu 0.05 --dt 0.001 --lambda -0.05 --E0 144 > "$WORK/smoke.out" 2>&1; }
build_fallback() {
  set_status BUILD "shipped binary failed its smoke test; building from the bundled source"
  local i cargo
  if [ "$MODE" = gce ]; then
    for i in $(seq 1 60); do
      command -v fuser >/dev/null 2>&1 && fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || break
      log INFO "waiting for the dpkg lock ($i/60)"; sleep 10
    done
    for i in 1 2 3; do
      DEBIAN_FRONTEND=noninteractive apt-get update -qq >> "$LOG" 2>&1 \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq build-essential pkg-config >> "$LOG" 2>&1 && break
      log WARN "apt attempt $i failed"; sleep 20
    done
    if [ ! -x /root/.cargo/bin/cargo ]; then
      for i in 1 2 3; do curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal >> "$LOG" 2>&1 && break; sleep 20; done
    fi
  fi
  cargo=$(command -v cargo 2>/dev/null || echo "${HOME:-/root}/.cargo/bin/cargo")
  [ -x "$cargo" ] || { log ERROR "no cargo after install attempts"; return 1; }
  rm -rf "$WORK/build"; mkdir -p "$WORK/build"
  tar -xzf "$WORK/job/src.tar.gz" -C "$WORK/build"
  (cd "$WORK/build" && "$cargo" build --release) >> "$LOG" 2>&1
}
set_status SMOKE "binary smoke test"
if ! smoke "$BIN"; then
  log WARN "shipped binary failed: $(tail -5 "$WORK/smoke.out" | tr '\n' ' ')"
  [ "$NO_BUILD" = 1 ] && die FAILED_BUILD 12 "shipped binary unusable ($(tail -2 "$WORK/smoke.out" | tr '\n' ' ')) and the build fallback is disabled"
  build_fallback || die FAILED_BUILD 12 "build fallback failed; see runner.log"
  BIN="$WORK/build/target/release/dual_scale_scout"
  smoke "$BIN" || die FAILED_BUILD 12 "rebuilt binary also fails the smoke test: $(tail -3 "$WORK/smoke.out" | tr '\n' ' ')"
fi

# ---------------------------------------------------------------- checkpoint recovery
if [ ! -f "$WORK/eval.ckpt" ] && [ ! -f "$WORK/eval.ckpt.prev" ]; then
  r1=0; store_get "$PREFIX/ckpt/eval.ckpt" "$WORK/eval.ckpt" || r1=$?
  r2=0; store_get "$PREFIX/ckpt/eval.ckpt.prev" "$WORK/eval.ckpt.prev" || r2=$?
  if [ "$r1" = 0 ] || [ "$r2" = 0 ]; then
    log INFO "checkpoint restored from the bucket (latest rc=$r1, prev rc=$r2): this run RESUMES"
  else
    log INFO "no checkpoint locally or in the bucket: starting from the beginning"
  fi
else
  log INFO "local checkpoint present: this run RESUMES"
fi

# ---------------------------------------------------------------- heartbeat (never fatal)
heartbeat() {
  trap - ERR TERM INT
  set +e
  local last_up=0 now
  while sleep "$HEARTBEAT_S"; do
    now=$(date +%s)
    attr heartbeat "$(ts)"
    [ -f "$WORK/progress.json" ] && attr progress "$(head -c 1500 "$WORK/progress.json")"
    attr load "$(cut -d' ' -f1-3 /proc/loadavg)"
    attr last_log "$(grep -a -v '^[[:space:]]*$' "$WORK/scout.log" 2>/dev/null | tail -1 | cut -c1-300)"
    if [ $((now - last_up)) -ge "$UPLOAD_S" ]; then
      snapshot_ckpt
      for f in progress.json runner.log scout.log; do [ -f "$WORK/$f" ] && store_put "$WORK/$f" "$PREFIX/out/$f"; done
      last_up=$now
    fi
  done
}
heartbeat &
HB_PID=$!

# ---------------------------------------------------------------- run, with retries from the checkpoint
attempt=0; resets=0
while :; do
  attempt=$((attempt + 1))
  set_status RUNNING "attempt $attempt/$MAX_ATTEMPTS, boot $BOOT_N"
  echo "=== attempt $attempt boot $BOOT_N $(ts) ===" >> "$WORK/scout.log"
  # shellcheck disable=SC2086
  "$BIN" scout --M "$M" --ic adv --align free --phases-start "$WORK/job/seed_phases.txt" \
    --ckpt "$WORK/eval.ckpt" --ckpt-every-s "$CKPT_S" --progress "$WORK/progress.json" \
    --nu 0.05 --dt 0.0000025 --steps 0 --every 1 --lambda -0.05 --E0 144 \
    --phases-out "$WORK/polished_phases.txt" $EXTRA_ARGS > "$WORK/scout.out" 2>> "$WORK/scout.log" &
  SCOUT_PID=$!
  rc=0; wait "$SCOUT_PID" || rc=$?
  SCOUT_PID=""
  [ "$rc" = 0 ] && break
  tail_msg=$(grep -a -v '^[[:space:]]*$' "$WORK/scout.log" | tail -3 | tr '\n' ' ' | cut -c1-400 || true)
  case "$rc" in
    3)  resets=$((resets + 1))
        q="$WORK/quarantine/$(date -u +%Y%m%dT%H%M%S)"; mkdir -p "$q"
        mv -f "$WORK"/eval.ckpt* "$q"/ 2>/dev/null || true
        for f in "$q"/*; do store_put "$f" "$PREFIX/ckpt-quarantine/$(basename "$q")/$(basename "$f")" || true; done
        [ "$resets" -le 2 ] || die FAILED_RUN 13 "checkpoint unusable $resets times: $tail_msg"
        log WARN "CHECKPOINT UNUSABLE (exit 3): quarantined to $q and the bucket; restarting from the beginning: $tail_msg"
        ;;
    4)  die FAILED_INPUT 11 "the scout refused its inputs (exit 4): $tail_msg" ;;
    *)  [ "$attempt" -lt "$MAX_ATTEMPTS" ] || die FAILED_RUN 13 "exit $rc on attempt $attempt/$MAX_ATTEMPTS: $tail_msg"
        log WARN "scout exited $rc (attempt $attempt/$MAX_ATTEMPTS), retrying from the checkpoint in $((30 * attempt))s: $tail_msg"
        sleep $((30 * attempt))
        ;;
  esac
done
kill "$HB_PID" 2>/dev/null || true

# ---------------------------------------------------------------- verify and publish the result
set_status VERIFY "checking the output"
P="$WORK/polished_phases.txt"; S="$WORK/job/seed_phases.txt"
[ -f "$P" ] || die FAILED_RUN 13 "exit 0 but no polished phases file"
head -1 "$P" | grep -qx "# scout adversarial phases M=$M" || die FAILED_RUN 13 "polished phases header wrong"
[ "$(wc -l < "$P")" = "$(wc -l < "$S")" ] || die FAILED_RUN 13 "polished phases has $(wc -l < "$P") lines, seed has $(wc -l < "$S")"
# 2026-09-17 incident: an unflushed write across a preemption boundary left a handful of NUL
# bytes in scout.log (the log is intentionally never fsync'd -- only the checkpoint is). `grep`
# treats any file containing a NUL byte as binary and silently matches nothing at all, which
# turned a FULLY SUCCESSFUL 34-hour run into a false FAILED_RUN, with the actual answer sitting
# untouched in the log the whole time. `-a` forces text search regardless of binary detection.
init=$(grep -a -o 'initial exact |S| = [0-9]*' "$WORK/scout.log" | tail -1 | grep -a -o '[0-9]*$' || true)
last=$(grep -a 'sweep [0-9]* done, best=' "$WORK/scout.log" | tail -1 || true)
final=$(printf '%s' "$last" | sed -n 's/.*best=\([0-9]*\).*/\1/p')
sweeps=$(printf '%s' "$last" | sed -n 's/.*sweep \([0-9]*\) done.*/\1/p')
[ -n "$init" ] && [ -n "$final" ] || die FAILED_RUN 13 "could not read the exact |S| values from scout.log"
flips=$(paste -d' ' <(tail -n +2 "$S") <(tail -n +2 "$P") | awk '$4 != $8' | wc -l)
sha=$(sha256sum "$P" | cut -d' ' -f1)
printf '{"m":%s,"initial_exact_S":"%s","final_exact_S":"%s","sweeps":%s,"polish_flips":%s,"polished_sha256":"%s","attempts":%s,"boots":%s,"checkpoint_resets":%s,"instance":"%s","machine":"%s","finished":"%s"}\n' \
  "$M" "$init" "$final" "$sweeps" "$flips" "$sha" "$attempt" "$BOOT_N" "$resets" "$INSTANCE" "$MTYPE" "$(ts)" > "$WORK/result.json"
store_put "$P" "$PREFIX/out/polished_phases.txt" || die FAILED_RUN 13 "result computed but the polished phases could not be uploaded"
store_put "$WORK/result.json" "$PREFIX/out/result.json" || die FAILED_RUN 13 "result computed but result.json could not be uploaded"
touch "$WORK/DONE"
store_put "$WORK/DONE" "$PREFIX/out/DONE" || true
set_status DONE "initial |S|=$init final |S|=$final sweeps=$sweeps polish_flips=$flips"
finish 0
