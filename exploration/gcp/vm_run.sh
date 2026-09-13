#!/usr/bin/env bash
# TIER C — runs ON THE VM. Build the scout once, then (re)start the M=32 alignment from the
# checkpoint. Idempotent: safe to run on every boot, which is how preemption becomes a
# one-sweep loss instead of a restart — the startup script calls this.
set -euo pipefail
cd /opt/scout

if ! command -v cargo >/dev/null 2>&1; then
  sudo apt-get update -qq && sudo apt-get install -y -qq build-essential curl pkg-config >/dev/null
  curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal >/dev/null
fi
export PATH="$HOME/.cargo/bin:$PATH"

# Build for THIS CPU. The alignment is integer-op bound; this is a small, free win.
if [ ! -x target/release/dual_scale_scout ]; then
  RUSTFLAGS="-C target-cpu=native" cargo build --release --quiet
fi

[ -f S4_M32_align.ckpt ] || { echo "no checkpoint present; refusing to start from scratch"; exit 1; }
echo "== $(date -u +%FT%TZ) resuming from: $(head -1 S4_M32_align.ckpt)" >> align.log

# Same arguments as the laptop run, same checkpoint path, so the two are interchangeable.
exec ./target/release/dual_scale_scout scout --M 32 --ic adv --align free \
  --ckpt S4_M32_align.ckpt \
  --nu 0.05 --dt 0.0000625 --steps 0 --every 1 --lambda -0.05 --E0 144 \
  --phases-out S4_M32_phases.txt >> align.log 2>&1
