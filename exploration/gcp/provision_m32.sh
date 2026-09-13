#!/usr/bin/env bash
# TIER C — EXPLORATORY, NO CLAIMS.
#
# Provision a 16-vCPU SPOT instance for the M=32 greedy alignment, ship the scout source and
# the current checkpoint to it, build, and resume. Run this ON THE LAPTOP, from the repo root.
#
# Everything here was chosen against a measurement, not a guess:
#   - 16 vCPU, not 64: the workload saturates ~12 threads and is then bandwidth-bound
#     (compute brief §1.1). 16 vCPU = 8 physical cores ≈ 2x this laptop's 4.
#   - c2 (Cascade Lake, 3.1–3.8 GHz sustained): the alignment is integer-op bound on a 1.4 MB
#     working set, so CLOCK matters and memory does not. AVX-512 is irrelevant to it.
#   - SPOT with --instance-termination-action=STOP, not DELETE: on preemption the boot disk
#     (and the checkpoint on it) survives, and `gcloud compute instances start` resumes.
#     The alignment checkpoints every sweep, so a preemption costs one sweep (~6 min here).
#   - --max-run-duration caps the bill by construction: 30 h x ~$0.30/h ≈ $9 worst case
#     against the authorised $50 (confirm current spot pricing before running).
#
# Usage:   bash exploration/gcp/provision_m32.sh          # create + ship + start
#          bash exploration/gcp/provision_m32.sh status   # tail the log
#          bash exploration/gcp/provision_m32.sh fetch    # copy phases + checkpoint back
#          bash exploration/gcp/provision_m32.sh destroy  # delete the VM (disk included)
set -euo pipefail

PROJECT="gen-lang-client-0625573011"
ZONE="us-central1-a"
NAME="mf-m32-align"
MACHINE="c2-standard-16"
IMAGE_FAMILY="debian-12"
IMAGE_PROJECT="debian-cloud"
MAX_RUN="30h"
REMOTE_DIR="/opt/scout"

CKPT="exploration/scout_runs/S4_M32_align.ckpt"
SRC="exploration/dual_scale_scout_rs"

gc() { gcloud --project "$PROJECT" --quiet "$@"; }

case "${1:-create}" in
  create)
    [ -f "$CKPT" ] || { echo "no checkpoint at $CKPT — refusing to start from scratch on a paid machine"; exit 1; }
    echo "== checkpoint being shipped: $(head -1 "$CKPT")"
    echo "== creating $MACHINE SPOT in $ZONE (cap $MAX_RUN, STOP on preemption) =="
    gc compute instances create "$NAME" \
      --zone="$ZONE" --machine-type="$MACHINE" \
      --provisioning-model=SPOT --instance-termination-action=STOP \
      --max-run-duration="$MAX_RUN" \
      --image-family="$IMAGE_FAMILY" --image-project="$IMAGE_PROJECT" \
      --boot-disk-size=20GB \
      --metadata-from-file=startup-script=exploration/gcp/vm_startup.sh \
      --labels=purpose=m32-alignment,tier=c
    echo "== waiting for ssh =="
    for i in $(seq 1 30); do
      gc compute ssh "$NAME" --zone="$ZONE" --command="true" 2>/dev/null && break
      sleep 10
    done
    echo "== shipping source + checkpoint =="
    gc compute ssh "$NAME" --zone="$ZONE" --command="sudo mkdir -p $REMOTE_DIR && sudo chown \$USER $REMOTE_DIR"
    gc compute scp --zone="$ZONE" --recurse "$SRC/src" "$SRC/Cargo.toml" "$SRC/Cargo.lock" "$NAME:$REMOTE_DIR/" 2>/dev/null \
      || gc compute scp --zone="$ZONE" --recurse "$SRC/src" "$SRC/Cargo.toml" "$NAME:$REMOTE_DIR/"
    gc compute scp --zone="$ZONE" "$CKPT" "$NAME:$REMOTE_DIR/S4_M32_align.ckpt"
    gc compute scp --zone="$ZONE" exploration/gcp/vm_run.sh "$NAME:$REMOTE_DIR/run.sh"
    echo "== building and launching (rustup + cargo build, then resume from checkpoint) =="
    gc compute ssh "$NAME" --zone="$ZONE" --command="chmod +x $REMOTE_DIR/run.sh && nohup $REMOTE_DIR/run.sh > $REMOTE_DIR/run.out 2>&1 &"
    echo "== launched. status:  bash $0 status =="
    ;;
  status)
    gc compute ssh "$NAME" --zone="$ZONE" --command="tail -5 $REMOTE_DIR/align.log 2>/dev/null || tail -20 $REMOTE_DIR/run.out"
    ;;
  fetch)
    mkdir -p exploration/scout_runs/gcp
    gc compute scp --zone="$ZONE" "$NAME:$REMOTE_DIR/S4_M32_align.ckpt" exploration/scout_runs/gcp/
    gc compute scp --zone="$ZONE" "$NAME:$REMOTE_DIR/S4_M32_phases.txt" exploration/scout_runs/gcp/ 2>/dev/null || echo "(phases not written yet — not converged)"
    gc compute scp --zone="$ZONE" "$NAME:$REMOTE_DIR/align.log" exploration/scout_runs/gcp/
    echo "== fetched to exploration/scout_runs/gcp/ =="
    ;;
  start)   gc compute instances start "$NAME" --zone="$ZONE" ;;   # after a preemption STOP; startup script resumes
  destroy) gc compute instances delete "$NAME" --zone="$ZONE" ;;
  *) echo "usage: $0 [create|status|fetch|start|destroy]"; exit 2 ;;
esac
