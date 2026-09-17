#!/usr/bin/env bash
# TIER C — EXPLORATORY, NO CLAIMS. Resilience tests for the exact greedy's checkpointing
# (`--align free --ckpt`), run LOCALLY before any paid VM hour is spent on it.
#
# The claim under test: a run interrupted at ANY checkpoint, in ANY phase (class set, initial
# exact |S|, sweeps), and resumed, produces the uninterrupted run's output BYTE FOR BYTE and the
# same exact integers. Method: kill the process after every k-th save (`--die-after-saves k`,
# saves forced on every chunk/class with `--ckpt-every-s 0`), resume, repeat until it finishes.
# Controls, each demonstrated to fire: a truncated latest checkpoint falls back to `.prev`; two
# corrupt checkpoints exit 3; a different seed file exits 4; and the byte comparison used as the
# verdict is shown to catch a single flipped sign.
#
#   bash exploration/gcp/test_ckpt_resilience.sh WORKDIR
set -uo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
W="${1:?workdir}"; mkdir -p "$W"
BIN="$REPO/exploration/dual_scale_scout_rs/target/release/dual_scale_scout"
RUNS="$REPO/exploration/scout_runs"
COMMON=(--ic adv --nu 0.05 --dt 0.00025 --steps 0 --every 1 --lambda -0.05 --E0 144 --align free)
FAIL=0
pass() { echo "PASS  $*"; }
fail() { echo "FAIL  $*"; FAIL=1; }

# case name | M | seed file ("" = all +1) | k for the kill loop | expected initial |S| | expected final |S|
awk 'NR==1{print;next} NR>=2 && NR<=41 {$4=-$4} {print}' "$RUNS/S5_M16_phases_jacobi.txt" > "$W/seed_M16_perturbed.txt"
CASES=(
  "M8_scratch|8||37||822566075728"
  "M16_seed|16|$RUNS/S5_M16_phases_jacobi.txt|997|17175910896716672|17175910896716672"
  "M16_perturbed|16|$W/seed_M16_perturbed.txt|997|16788833804852576|17175910896716672"
)

run() {  # name, M, seed, extra args... ; writes $W/$name.{txt,log}; echoes exit code
  local name=$1 m=$2 seed=$3; shift 3
  local sargs=(); [ -n "$seed" ] && sargs=(--phases-start "$seed")
  "$BIN" scout --M "$m" "${COMMON[@]}" "${sargs[@]}" "$@" --phases-out "$W/$name.txt" >> "$W/$name.log" 2>&1
  echo $?
}

for c in "${CASES[@]}"; do
  IFS='|' read -r name m seed k want_init want_final <<< "$c"
  echo "== $name (M=$m, kill after every $k saves) =="
  rm -f "$W/$name"* "$W/${name}_ref"*
  # 1. uninterrupted reference, no checkpoint at all
  rc=$(run "${name}_ref" "$m" "$seed")
  [ "$rc" = 0 ] || fail "$name reference exited $rc"
  init=$(grep -o "initial exact |S| = [0-9]*" "$W/${name}_ref.log" | grep -o "[0-9]*$")
  final=$(grep "sweep .* done, best=" "$W/${name}_ref.log" | tail -1 | grep -o "best=[0-9]*" | cut -d= -f2)
  sweeps=$(grep -c "sweep .* done, best=" "$W/${name}_ref.log")
  [ -z "$want_init" ] || { [ "$init" = "$want_init" ] && pass "$name reference initial |S| = $init" || fail "$name reference initial |S| $init != $want_init"; }
  [ "$final" = "$want_final" ] && pass "$name reference final |S| = $final ($sweeps sweeps)" || fail "$name reference final |S| $final != $want_final"
  # 2. kill-and-resume loop
  launches=0; rc=75
  while [ "$rc" = 75 ]; do
    rc=$(run "$name" "$m" "$seed" --ckpt "$W/$name.ckpt" --ckpt-every-s 0 --die-after-saves "$k")
    launches=$((launches + 1))
    [ "$launches" -gt 5000 ] && { fail "$name did not finish in 5000 launches"; break; }
  done
  [ "$rc" = 0 ] || fail "$name kill loop ended with exit $rc"
  resumed=$(grep -c "RESUMED from" "$W/$name.log")
  phases_hit=$(grep -o "RESUMED from .* (phase=[a-z]*)" "$W/$name.log" | grep -o "phase=[a-z]*" | sort | uniq -c | tr '\n' ' ')
  echo "      $launches launches, $resumed resumes; resumed in: $phases_hit"
  cmp -s "$W/$name.txt" "$W/${name}_ref.txt" && pass "$name resumed output byte-identical to uninterrupted" || fail "$name resumed output DIFFERS"
  rfinal=$(grep "sweep .* done, best=" "$W/$name.log" | tail -1 | grep -o "best=[0-9]*" | cut -d= -f2)
  [ "$rfinal" = "$final" ] && pass "$name resumed final |S| = $rfinal" || fail "$name resumed final |S| $rfinal != $final"
done

echo "== class-pass resume (the kill loops above never land there: the class set saturates within a few chunks) =="
for spec in "8||M8_scratch_ref" "16|$RUNS/S5_M16_phases_jacobi.txt|M16_seed_ref"; do
  IFS='|' read -r mm seed ref <<< "$spec"
  rm -f "$W"/cls$mm*
  rc=$(run cls$mm "$mm" "$seed" --ckpt "$W/cls$mm.ckpt" --ckpt-every-s 0 --die-after-saves 1)
  [ "$rc" = 75 ] || fail "M=$mm class-pass setup exited $rc"
  head -1 "$W/cls$mm.ckpt" | grep -q "phase=classes chunk=1\$" && pass "M=$mm killed inside the class pass (checkpoint phase=classes chunk=1)" || fail "M=$mm first checkpoint is not in the class pass: $(head -1 "$W/cls$mm.ckpt" | cut -c1-100)"
  rc=$(run cls$mm "$mm" "$seed" --ckpt "$W/cls$mm.ckpt" --ckpt-every-s 0)
  grep -q "RESUMED from .*(phase=classes)" "$W/cls$mm.log" && pass "M=$mm resumed IN the class pass" || fail "M=$mm did not resume in the class pass"
  grep -o "class set saturated after [0-9]*/[0-9]* chunks.*" "$W/cls$mm.log" | tail -1 | sed 's/^/      /'
  [ "$rc" = 0 ] && cmp -s "$W/cls$mm.txt" "$W/$ref.txt" && pass "M=$mm class-pass resume: output byte-identical to uninterrupted" || fail "M=$mm class-pass resume: rc=$rc or output differs"
done

echo "== resume from an ALREADY phase=done checkpoint (2026-09-17 incident: the real M=64 run wrote"
echo "   this exact state to eval.ckpt and completed normally in the SAME process; a fresh launch"
echo "   loading that checkpoint -- exactly what a preemption right after convergence causes, and"
echo "   what a manual retry after any failure does -- hit a FATAL 'checkpoint field s missing' and"
echo "   quarantined a perfectly valid, fully-converged checkpoint, discarding it) =="
rm -f "$W"/done8*
rc=$(run done8_ref 8 "" --ckpt "$W/done8_ref.ckpt" --ckpt-every-s 0)
[ "$rc" = 0 ] || fail "done8 reference exited $rc"
head -1 "$W/done8_ref.ckpt" | grep -q "phase=done" \
  || fail "done8 setup: eval.ckpt is not phase=done after natural completion: $(head -1 "$W/done8_ref.ckpt")"
# a FRESH launch against that same, untouched, already-done checkpoint -- no kill involved at all
rc=$(run done8_resumed 8 "" --ckpt "$W/done8_ref.ckpt" --ckpt-every-s 0)
if [ "$rc" = 0 ] && grep -q "RESUMED from .*(phase=done)" "$W/done8_resumed.log" && ! grep -q "FATAL" "$W/done8_resumed.log" \
   && cmp -s "$W/done8_resumed.txt" "$W/M8_scratch_ref.txt"; then
  pass "fresh launch against an already-done checkpoint: no FATAL, output byte-identical"
else
  fail "fresh launch against an already-done checkpoint: rc=$rc; $(grep -m1 FATAL "$W/done8_resumed.log" || echo 'no FATAL line')"
fi

echo "== controls =="
# harness can fail: one flipped sign must be caught by the same byte comparison
awk 'NR==2{$4=-$4} {print}' "$W/M8_scratch_ref.txt" > "$W/flip1.txt"
cmp -s "$W/flip1.txt" "$W/M8_scratch_ref.txt" && fail "byte comparison did NOT catch a flipped sign" || pass "byte comparison catches a single flipped sign"

# truncated latest checkpoint -> resume from .prev, same output
rm -f "$W"/trunc*; rc=$(run trunc 8 "" --ckpt "$W/trunc.ckpt" --ckpt-every-s 0 --die-after-saves 1500)
[ "$rc" = 75 ] || fail "truncation setup exited $rc"
head -c $(( $(stat -c %s "$W/trunc.ckpt") / 2 )) "$W/trunc.ckpt" > "$W/trunc.half" && mv "$W/trunc.half" "$W/trunc.ckpt"
rc=$(run trunc 8 "" --ckpt "$W/trunc.ckpt" --ckpt-every-s 0)
grep -q "RESUMING FROM THE PREVIOUS SAVE" "$W/trunc.log" && pass "truncated checkpoint detected, fell back to .prev" || fail "truncated checkpoint not detected"
[ "$rc" = 0 ] && cmp -s "$W/trunc.txt" "$W/M8_scratch_ref.txt" && pass "run resumed from .prev is byte-identical" || fail "run resumed from .prev differs (rc=$rc)"

# both checkpoints corrupt -> exit 3, never a silent fresh start
rm -f "$W"/both*; rc=$(run both 8 "" --ckpt "$W/both.ckpt" --ckpt-every-s 0 --die-after-saves 1500)
echo garbage > "$W/both.ckpt"; echo garbage > "$W/both.ckpt.prev"
rc=$(run both 8 "" --ckpt "$W/both.ckpt" --ckpt-every-s 0)
[ "$rc" = 3 ] && pass "two corrupt checkpoints -> exit 3 (checkpoint unusable)" || fail "two corrupt checkpoints exited $rc, expected 3"

# checkpoint from a different seed -> exit 4
rm -f "$W"/seedmix*; rc=$(run seedmix 16 "$RUNS/S5_M16_phases_jacobi.txt" --ckpt "$W/seedmix.ckpt" --ckpt-every-s 0 --die-after-saves 5)
rc=$(run seedmix 16 "$W/seed_M16_perturbed.txt" --ckpt "$W/seedmix.ckpt" --ckpt-every-s 0)
[ "$rc" = 4 ] && pass "checkpoint from another seed -> exit 4" || fail "seed mismatch exited $rc, expected 4"

echo; [ "$FAIL" = 0 ] && echo "ALL RESILIENCE TESTS PASSED" || echo "SOME RESILIENCE TESTS FAILED"
exit "$FAIL"
