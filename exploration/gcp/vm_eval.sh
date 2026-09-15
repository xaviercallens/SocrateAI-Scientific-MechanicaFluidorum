#!/usr/bin/env bash
# TIER C — runs ON THE VM. Build once, run the exact evaluation of seed_phases.txt at M (class
# set, exact i128 |S|, exact greedy polish with a per-sweep checkpoint), upload every artifact to
# the bucket, and POWER OFF. Idempotent: the startup script calls this on every boot; after a
# preemption the free path resumes from eval.ckpt (the seed is applied only when no checkpoint
# exists, so a resumed run never re-seeds).
set -uo pipefail
cd /opt/scout
BUCKET="$(cat bucket.txt 2>/dev/null || true)"
M="$(cat M.txt)"

log() { echo "== $(date -u +%FT%TZ) $*" | tee -a eval.log; }
upload() {
  [ -n "$BUCKET" ] || return 0
  for f in eval.ckpt polished_phases.txt eval.log run.out dir_listing.txt; do
    [ -f "$f" ] && gsutil -q cp "$f" "gs://$BUCKET/" 2>/dev/null
  done
}
# Backstop: every exit path uploads whatever exists, even one this script's own author didn't
# think to add an explicit `upload` call to (an early-exit branch shipped without one once --
# see the incident note in provision_eval.sh's changelog). A trap cannot save a run killed by
# `poweroff` mid-flight, so explicit `upload` calls before poweroff are still kept below too;
# this is defence in depth, not a replacement for them.
trap 'upload' EXIT
ls -la > dir_listing.txt 2>&1 || true

if ! command -v cargo >/dev/null 2>&1 && [ ! -x "$HOME/.cargo/bin/cargo" ]; then
  sudo apt-get update -qq && sudo apt-get install -y -qq build-essential curl pkg-config >/dev/null
  curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal >/dev/null
fi
export PATH="$HOME/.cargo/bin:$PATH"

if [ ! -x target/release/dual_scale_scout ]; then
  log "building (target-cpu=native)"
  RUSTFLAGS="-C target-cpu=native" cargo build --release --quiet || { log "BUILD FAILED"; upload; sudo poweroff; }
fi

[ -f seed_phases.txt ] || { log "no seed phases; nothing to evaluate"; upload; sudo poweroff; }
log "exact evaluation at M=$M of $(head -1 seed_phases.txt); nproc=$(nproc)"
( while sleep 900; do upload; done ) &
UPLOADER=$!

./target/release/dual_scale_scout scout --M "$M" --ic adv --align free \
  --phases-start seed_phases.txt --ckpt eval.ckpt \
  --nu 0.05 --dt 0.0000025 --steps 0 --every 1 --lambda -0.05 --E0 144 \
  --phases-out polished_phases.txt >> eval.log 2>&1
RC=$?
kill "$UPLOADER" 2>/dev/null

if [ -f polished_phases.txt ]; then log "DONE — polished phases written (rc=$RC)"; else log "scout exited rc=$RC without phases"; fi
upload
log "powering off: the job is over"
sudo poweroff
