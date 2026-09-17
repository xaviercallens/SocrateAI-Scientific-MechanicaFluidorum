#!/usr/bin/env bash
# TIER C — EXPLORATORY, NO CLAIMS. Control-flow tests of launch_m64.sh (+ provision_eval.sh)
# against a STUB gcloud that answers from a small state directory -- no cloud is contacted.
# Every branch that can delete, resume, create or refuse is driven, and each scenario asserts both
# the exit code and which gcloud calls were (and were NOT) made. A stub answering an unexpected
# call exits 2, so an unplanned gcloud invocation fails the scenario instead of passing silently.
#
#   bash exploration/gcp/test_launch_stub.sh WORKDIR
set -uo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
T="${1:?workdir}"; rm -rf "$T"; mkdir -p "$T/bin"
FAIL=0
pass() { echo "PASS  $*"; }
fail() { echo "FAIL  $*"; FAIL=1; }

cat > "$T/bin/gcloud" <<'STUB'
#!/usr/bin/env bash
S="${STUB_STATE:?}"
echo "$*" >> "$S/calls.log"
a="$*"
case "$a" in
  "config get-value account") echo tester@example.com ;;
  *"compute instances list"*) [ -f "$S/instance" ] && echo us-central1-a; exit 0 ;;
  *"compute instances describe"*"value(status,lastStartTimestamp"*)
      printf '%s\t%s\t%s\n' "$(cat "$S/instance")" "2026-09-15T12:00:00+00:00" c2-standard-8 ;;
  *"compute instances describe"*"value(status)"*) cat "$S/instance" ;;
  *"compute instances get-serial-port-output"*) echo "serial: boot"; echo "MF-EVAL 2026 [STATUS] $(cat "$S/guest_status" 2>/dev/null)" ;;
  *"compute instances delete"*) rm -f "$S/instance" ;;
  *"compute instances add-metadata"*) echo "$*" >> "$S/metadata_refreshes.log" ;;
  *"compute instances start"*) echo RUNNING > "$S/instance" ;;
  *"compute instances create"*) echo RUNNING > "$S/instance"; echo "mf-eval us-central1-a c2-standard-8 true RUNNING" ;;
  *"get-guest-attributes"*"mf/status"*) cat "$S/guest_status" 2>/dev/null ;;
  *"get-guest-attributes"*) printf 'status\t%s\nheartbeat\t%s\n' "$(cat "$S/guest_status" 2>/dev/null)" "$(date -u +%FT%TZ)" ;;
  *"compute regions describe"*)
      echo '{"quotas":[{"metric":"CPUS","limit":24,"usage":0},{"metric":"C2_CPUS","limit":8,"usage":0},{"metric":"N2_CPUS","limit":8,"usage":0},{"metric":"N2D_CPUS","limit":8,"usage":0}]}' ;;
  *"projects describe"*) echo gen-lang-client-0625573011 ;;
  *"storage buckets describe"*) exit 0 ;;
  *"storage ls"*"out/DONE"*) [ -f "$S/done" ] || exit 1; echo gs://b/m64/out/DONE ;;
  *"storage ls"*"ckpt/eval.ckpt"*) [ -f "$S/ckpt" ] || exit 1; echo gs://b/m64/ckpt/eval.ckpt ;;
  *"storage ls"*) exit 1 ;;
  *"storage cp"*) exit 0 ;;
  *"storage cat"*) exit 1 ;;
  *) echo "STUB: unhandled gcloud call: $*" >&2; exit 2 ;;
esac
STUB
chmod +x "$T/bin/gcloud"
export PATH="$T/bin:$PATH"

# a throwaway copy of the tree, so logs/schedules the scripts write never land in the repo
R="$T/repo"; mkdir -p "$R/exploration/gcp" "$R/exploration/scout_runs"
cp "$REPO"/exploration/gcp/{launch_m64.sh,provision_eval.sh,vm_eval.sh} "$R/exploration/gcp/"
ln -s "$REPO/exploration/dual_scale_scout_rs" "$R/exploration/dual_scale_scout_rs"
ln -s "$REPO/exploration/scout_runs/S5_M64_phases.txt" "$R/exploration/scout_runs/S5_M64_phases.txt"

scenario() {  # name instance_state guest_status ckpt(0/1) done(0/1) [launcher args]
  local name=$1; shift
  export STUB_STATE="$T/$name"; mkdir -p "$STUB_STATE"; : > "$STUB_STATE/calls.log"
  [ "$1" != none ] && echo "$1" > "$STUB_STATE/instance"
  echo "$2" > "$STUB_STATE/guest_status"
  [ "$3" = 1 ] && touch "$STUB_STATE/ckpt"
  [ "$4" = 1 ] && touch "$STUB_STATE/done"
  shift 4
  (cd "$R" && bash exploration/gcp/launch_m64.sh "$@") > "$T/$name.out" 2>&1
  echo $?
}
called() { grep -q -- "$2" "$T/$1/calls.log"; }
unhandled() { grep -q "STUB: unhandled" "$T/$1.out"; }

rc=$(scenario dead_old TERMINATED RUNNING 0 0)
{ [ "$rc" = 0 ] && called dead_old "get-serial-port-output" && called dead_old "instances delete" \
  && called dead_old "instances create" && ! called dead_old "instances start" && ! unhandled dead_old \
  && [ -f "$R/exploration/scout_runs/gcp/m64_monitor_schedule.txt" ] && ls "$R"/exploration/scout_runs/gcp/serial-* >/dev/null 2>&1; } \
  && pass "dead instance, no checkpoint: serial log saved, deleted, recreated, schedule written" \
  || fail "dead instance, no checkpoint (rc=$rc): $(tail -5 "$T/dead_old.out")"

rc=$(scenario live RUNNING RUNNING 0 0)
{ [ "$rc" = 1 ] && ! called live "instances delete" && ! called live "instances create" && grep -q "not touching it" "$T/live.out"; } \
  && pass "live instance: refused, nothing deleted or created" || fail "live instance (rc=$rc): $(tail -3 "$T/live.out")"

rc=$(scenario resumable TERMINATED RUNNING 1 0)
{ [ "$rc" = 0 ] && called resumable "instances start" && called resumable "instances add-metadata" && ! called resumable "instances delete" && ! called resumable "instances create" && ! unhandled resumable; } \
  && pass "preempted job with a bucket checkpoint: resumed, not recreated, startup script refreshed first" || fail "resumable (rc=$rc): $(tail -5 "$T/resumable.out")"

rc=$(scenario fresh TERMINATED RUNNING 1 0 --fresh)
{ [ "$rc" = 0 ] && called fresh "instances delete" && called fresh "instances create" && ! called fresh "instances start"; } \
  && pass "--fresh: deleted and recreated despite the checkpoint" || fail "--fresh (rc=$rc): $(tail -5 "$T/fresh.out")"

rc=$(scenario done none RUNNING 0 1)
{ [ "$rc" = 0 ] && ! called done "instances create" && grep -q "already finished" "$T/done.out"; } \
  && pass "result already in the bucket: stops, creates nothing" || fail "done (rc=$rc): $(tail -3 "$T/done.out")"

rc=$(scenario bootfail none FAILED_INPUT 0 0)
{ [ "$rc" = 1 ] && called bootfail "instances create" && grep -q "reports FAILED_INPUT" "$T/bootfail.out" && called bootfail "get-serial-port-output"; } \
  && pass "VM reports FAILED_INPUT after boot: launcher exits 1 and shows the runner's lines" || fail "bootfail (rc=$rc): $(tail -5 "$T/bootfail.out")"

rc=$(scenario clean none RUNNING 0 0)
{ [ "$rc" = 0 ] && ! called clean "instances delete" && called clean "instances create" && ! unhandled clean; } \
  && pass "no previous instance: straight to create, VM reports RUNNING" || fail "clean (rc=$rc): $(tail -5 "$T/clean.out")"

echo; echo "--- the schedule the launcher printed (clean scenario) ---"
sed -n '/MONITORING SCHEDULE/,$p' "$T/clean.out"
echo; [ "$FAIL" = 0 ] && echo "ALL LAUNCHER TESTS PASSED" || echo "SOME LAUNCHER TESTS FAILED"
exit "$FAIL"
