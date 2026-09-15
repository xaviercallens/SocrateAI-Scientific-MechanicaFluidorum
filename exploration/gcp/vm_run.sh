#!/usr/bin/env bash
# TIER C — runs ON THE VM. Build once, resume the M=32 alignment from the checkpoint, and when
# it finishes — converged OR crashed — upload every artifact to the bucket and POWER OFF, so a
# finished or broken job never sits on a paid machine. Idempotent: the startup script calls this
# on every boot, which is how a spot preemption becomes a one-sweep loss.
set -uo pipefail
cd /opt/scout
BUCKET="$(cat bucket.txt 2>/dev/null || true)"

log() { echo "== $(date -u +%FT%TZ) $*" | tee -a align.log; }
upload() {   # best-effort, never fatal: the disk keeps everything too (STOP, not DELETE)
  [ -n "$BUCKET" ] || return 0
  for f in S4_M32_align.ckpt S4_M32_phases.txt align.log run.out; do
    [ -f "$f" ] && gsutil -q cp "$f" "gs://$BUCKET/" 2>/dev/null
  done
}
# Backstop: an early-exit branch in this script's sibling (vm_eval.sh) shipped without an
# `upload` call once, so a fast failure left an empty bucket and no diagnostic trace at all
# (caught 2026-09-15). A trap cannot save a run `poweroff` kills mid-flight, so explicit
# `upload` calls before every `poweroff` below are kept too; this is defence in depth.
trap 'upload' EXIT

if ! command -v cargo >/dev/null 2>&1 && [ ! -x "$HOME/.cargo/bin/cargo" ]; then
  sudo apt-get update -qq && sudo apt-get install -y -qq build-essential curl pkg-config >/dev/null
  curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal >/dev/null
fi
export PATH="$HOME/.cargo/bin:$PATH"

if [ ! -x target/release/dual_scale_scout ]; then
  log "building (target-cpu=native)"
  RUSTFLAGS="-C target-cpu=native" cargo build --release --quiet || { log "BUILD FAILED"; upload; sudo poweroff; }
fi

[ -f S4_M32_align.ckpt ] || { log "no checkpoint present; refusing to start from scratch on a paid machine"; upload; sudo poweroff; }
log "resuming from: $(head -1 S4_M32_align.ckpt)"

# Periodic upload of the checkpoint while running, so a preemption that also loses the disk
# (it should not, with STOP — but belt and braces) still leaves the latest sweep in the bucket.
( while sleep 900; do upload; done ) &
UPLOADER=$!

./target/release/dual_scale_scout scout --M 32 --ic adv --align free \
  --ckpt S4_M32_align.ckpt \
  --nu 0.05 --dt 0.0000625 --steps 0 --every 1 --lambda -0.05 --E0 144 \
  --phases-out S4_M32_phases.txt >> align.log 2>&1
RC=$?
kill "$UPLOADER" 2>/dev/null

if [ -f S4_M32_phases.txt ]; then log "CONVERGED — phases written"; else log "scout exited rc=$RC without phases"; fi
upload
log "powering off: the job is over, the machine should not be billed for idling"
sudo poweroff
