#!/usr/bin/env bash
# TIER C — EXPLORATORY, NO CLAIMS. Local tests of the GCP runner (vm_eval.sh) in MF_MODE=local:
# the same script, with the metadata server replaced by MF_* variables, the bucket by a directory,
# and power-off by exit. Every failure path the first launch could have hit is driven on purpose
# and must end in its NAMED state with diagnostics in the "bucket" -- the property whose absence
# left an empty bucket on 2026-09-15.
#
#   bash exploration/gcp/test_runner_local.sh WORKDIR
set -uo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
T="${1:?workdir}"; rm -rf "$T"; mkdir -p "$T"
RUNS="$REPO/exploration/scout_runs"
RUNNER="$REPO/exploration/gcp/vm_eval.sh"
FAIL=0
pass() { echo "PASS  $*"; }
fail() { echo "FAIL  $*"; FAIL=1; }

echo "== bundle (the same code path provision_eval.sh create uses)"
bash "$REPO/exploration/gcp/provision_eval.sh" bundle 16 "$RUNS/S5_M16_phases_jacobi.txt" "$T/bundle" > "$T/bundle.log" 2>&1 \
  && pass "bundle built" || { fail "bundle failed: $(tail -3 "$T/bundle.log")"; exit 1; }
awk 'NR==1{print;next} NR>=2 && NR<=41 {$4=-$4} {print}' "$RUNS/S5_M16_phases_jacobi.txt" > "$T/perturbed.txt"

new_bucket() {  # name [seed] -> a fresh bucket dir holding the bundle (optionally with another seed)
  local b="$T/$1/bucket"; mkdir -p "$b/m16/job"; cp "$T/bundle"/* "$b/m16/job/"
  if [ -n "${2:-}" ]; then
    cp "$2" "$b/m16/job/seed_phases.txt"
    (cd "$b/m16/job" && sha256sum dual_scale_scout seed_phases.txt src.tar.gz job.env > manifest.sha256)
  fi
  echo "$b"
}
runner() {  # name bucket [extra env...] -> exit code; work dir $T/<name>/work
  local name=$1 bucket=$2; shift 2
  env MF_MODE=local MF_WORK="$T/$name/work" MF_LOCAL_BUCKET="$bucket" MF_BUCKET=local MF_PREFIX=m16 MF_M=16 \
      MF_CKPT_EVERY_S=1 MF_HOLD_S=0 MF_HEARTBEAT_S=1 MF_UPLOAD_S=1 MF_MAX_ATTEMPTS=2 "$@" \
      bash "$RUNNER" >> "$T/$name/runner.stdout" 2>&1
  echo $?
}
state() { sed -n 's/.*"state":"\([A-Z_]*\)".*/\1/p' "$1/m16/out/status.json" 2>/dev/null; }

# 1. happy path
b=$(new_bucket happy); rc=$(runner happy "$b")
[ "$rc" = 0 ] && [ "$(state "$b")" = DONE ] && pass "happy path: exit 0, state DONE" || fail "happy path: rc=$rc state=$(state "$b")"
grep -q '"final_exact_S":"17175910896716672"' "$b/m16/out/result.json" 2>/dev/null && pass "happy path: result.json final |S| = 17175910896716672" || fail "happy path: result.json wrong or missing"
cmp -s "$b/m16/out/polished_phases.txt" "$RUNS/S5_M16_phases_jacobi.txt" && pass "happy path: polished phases uploaded, identical to the seed (0 polish flips)" || fail "happy path: polished phases differ/missing"
[ -f "$b/m16/out/DONE" ] && [ -f "$b/m16/out/runner.log" ] && pass "happy path: DONE marker and runner.log in the bucket" || fail "happy path: DONE/runner.log missing"

# 2. a completed job is not rerun
rc=$(runner happy "$b")
[ "$rc" = 0 ] && grep -q "already complete" "$T/happy/work/runner.log" && pass "rerun after DONE: exits at once" || fail "rerun after DONE: rc=$rc"

# 3. the 2026-09-15 incident: the seed never arrived -> FAILED_INPUT, and the bucket says why
b=$(new_bucket noseed); rm "$b/m16/job/seed_phases.txt"; rc=$(runner noseed "$b")
[ "$rc" = 11 ] && [ "$(state "$b")" = FAILED_INPUT ] && pass "missing seed: FAILED_INPUT (exit 11)" || fail "missing seed: rc=$rc state=$(state "$b")"
grep -q "seed_phases.txt not fetched" "$b/m16/out/runner.log" 2>/dev/null && pass "missing seed: the reason is in the bucket's runner.log" || fail "missing seed: no diagnosis uploaded"

# 4. corrupted bundle -> sha256 refusal
b=$(new_bucket badsha); echo "tampered" >> "$b/m16/job/seed_phases.txt"; rc=$(runner badsha "$b")
[ "$rc" = 11 ] && grep -q "sha256 verification failed" "$b/m16/out/status.json" && pass "tampered seed: sha256 refusal (exit 11)" || fail "tampered seed: rc=$rc"

# 5. unusable binary, build disabled -> FAILED_BUILD with the smoke-test output uploaded
b=$(new_bucket badbin); echo "not an executable" > "$b/m16/job/dual_scale_scout"
(cd "$b/m16/job" && sha256sum dual_scale_scout seed_phases.txt src.tar.gz job.env > manifest.sha256)
rc=$(runner badbin "$b" MF_NO_BUILD=1)
[ "$rc" = 12 ] && [ "$(state "$b")" = FAILED_BUILD ] && [ -f "$b/m16/out/smoke.out" ] && pass "broken binary: FAILED_BUILD (exit 12), smoke output uploaded" || fail "broken binary: rc=$rc state=$(state "$b")"

# 6. unusable binary, build allowed -> the fallback builds the bundled source and the job completes
b=$(new_bucket rebuild); echo "not an executable" > "$b/m16/job/dual_scale_scout"
(cd "$b/m16/job" && sha256sum dual_scale_scout seed_phases.txt src.tar.gz job.env > manifest.sha256)
rc=$(runner rebuild "$b")
[ "$rc" = 0 ] && grep -q '"final_exact_S":"17175910896716672"' "$b/m16/out/result.json" 2>/dev/null && pass "broken binary + build fallback: rebuilt from src.tar.gz, job DONE" || fail "build fallback: rc=$rc"

# 7. bucket not writable -> FAILED_PREFLIGHT before any work, diagnosis kept locally
b=$(new_bucket ro); chmod -R a-w "$b"; rc=$(runner ro "$b"); chmod -R u+w "$b"
[ "$rc" = 10 ] && grep -q "cannot write to the bucket" "$T/ro/work/runner.log" && pass "read-only bucket: FAILED_PREFLIGHT (exit 10)" || fail "read-only bucket: rc=$rc"

# reference for the interruption tests: the perturbed seed needs a real polish (40 flips, 2 sweeps)
BIN="$REPO/exploration/dual_scale_scout_rs/target/release/dual_scale_scout"
"$BIN" scout --M 16 --ic adv --align free --phases-start "$T/perturbed.txt" --nu 0.05 --dt 0.0000025 --steps 0 --every 1 \
  --lambda -0.05 --E0 144 --phases-out "$T/perturbed_ref.txt" > /dev/null 2> "$T/perturbed_ref.log"

wait_phase() {  # workdir phase timeout_s
  local i
  for i in $(seq 1 "$3"); do grep -q "\"phase\":\"$2\"" "$1/progress.json" 2>/dev/null && return 0; sleep 1; done
  return 1
}

# 8. preemption: SIGTERM mid-sweep, then a FRESH VM (empty disk) resumes from the bucket's checkpoint
b=$(new_bucket preempt "$T/perturbed.txt")
# no ( ... ) wrapper: `env` execs bash, so $! IS the runner and SIGTERM reaches its trap
env MF_MODE=local MF_WORK="$T/preempt/work" MF_LOCAL_BUCKET="$b" MF_BUCKET=local MF_PREFIX=m16 MF_M=16 \
    MF_CKPT_EVERY_S=1 MF_HOLD_S=0 MF_HEARTBEAT_S=1 MF_UPLOAD_S=1 bash "$RUNNER" >> "$T/preempt.stdout" 2>&1 &
rp=$!
if wait_phase "$T/preempt/work" sweep 180; then
  sleep 4
  kill -TERM "$rp"; wait "$rp"; trc=$?
  pkill -f "dual_scale_scout scout --M 16 .*$T/preempt" 2>/dev/null
  [ "$trc" = 143 ] && [ -f "$b/m16/ckpt/eval.ckpt" ] && pass "SIGTERM mid-sweep: exit 143, checkpoint flushed to the bucket" || fail "SIGTERM: rc=$trc, bucket ckpt $(ls "$b/m16/ckpt" 2>/dev/null)"
  mv "$T/preempt/work" "$T/preempt/work.lost"            # a new VM: nothing on its disk
  rc=$(runner preempt "$b")
  grep -q "checkpoint restored from the bucket" "$T/preempt/work/runner.log" && pass "fresh VM: checkpoint restored from the bucket" || fail "fresh VM did not restore the checkpoint"
  grep -q "RESUMED from" "$T/preempt/work/scout.log" && pass "fresh VM: the scout RESUMED (did not restart)" || fail "fresh VM: scout did not resume"
  [ "$rc" = 0 ] && cmp -s "$b/m16/out/polished_phases.txt" "$T/perturbed_ref.txt" && pass "preempted + resumed on a new VM: output byte-identical to the uninterrupted run" || fail "preempt/resume: rc=$rc or output differs"
else
  fail "preemption test never reached the sweep phase"; kill "$rp" 2>/dev/null
fi

# 9. crash of the scout itself (SIGKILL, e.g. OOM) -> the runner retries from the checkpoint
b=$(new_bucket crash "$T/perturbed.txt")
env MF_MODE=local MF_WORK="$T/crash/work" MF_LOCAL_BUCKET="$b" MF_BUCKET=local MF_PREFIX=m16 MF_M=16 \
    MF_CKPT_EVERY_S=1 MF_HOLD_S=0 MF_HEARTBEAT_S=1 MF_UPLOAD_S=1 MF_MAX_ATTEMPTS=3 bash "$RUNNER" >> "$T/crash.stdout" 2>&1 &
cp=$!
if wait_phase "$T/crash/work" sweep 180; then
  sleep 4
  pkill -KILL -f "dual_scale_scout scout --M 16 .*$T/crash/work" && echo "      (scout SIGKILLed)"
  wait "$cp"; crc=$?
  [ "$crc" = 0 ] && grep -q "retrying from the checkpoint" "$T/crash/work/runner.log" \
    && cmp -s "$b/m16/out/polished_phases.txt" "$T/perturbed_ref.txt" \
    && pass "scout SIGKILLed mid-sweep: runner retried from the checkpoint, output byte-identical" || fail "scout crash recovery: rc=$crc"
else
  fail "crash test never reached the sweep phase"; kill "$cp" 2>/dev/null
fi

# 10. corrupt checkpoints on disk -> quarantined, restarted, still the right answer
b=$(new_bucket corrupt)
mkdir -p "$T/corrupt/work"; echo garbage > "$T/corrupt/work/eval.ckpt"; echo garbage > "$T/corrupt/work/eval.ckpt.prev"
rc=$(runner corrupt "$b")
[ "$rc" = 0 ] && grep -q "CHECKPOINT UNUSABLE" "$T/corrupt/work/runner.log" && [ -n "$(ls "$b/m16/ckpt-quarantine" 2>/dev/null)" ] \
  && grep -q '"final_exact_S":"17175910896716672"' "$b/m16/out/result.json" \
  && pass "corrupt checkpoints: quarantined (also in the bucket), restarted, correct result" || fail "corrupt checkpoints: rc=$rc"

# 11. telemetry was actually written
[ -s "$T/preempt/work/attrs/heartbeat" ] && [ -s "$T/preempt/work/attrs/progress" ] && [ -s "$T/preempt/work/attrs/status" ] \
  && pass "guest attributes written: status, heartbeat, progress ($(cat "$T/preempt/work/attrs/status"))" || fail "guest attributes missing"

echo; [ "$FAIL" = 0 ] && echo "ALL RUNNER TESTS PASSED" || echo "SOME RUNNER TESTS FAILED"
exit "$FAIL"
