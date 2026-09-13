#!/usr/bin/env bash
# TIER C — EXPLORATORY, NO CLAIMS.
#
# Provision a 16-vCPU SPOT instance for the M=32 greedy alignment, ship the scout source and the
# current checkpoint, build, resume — and make sure it costs as little as possible and cleans up
# after itself. Run ON THE LAPTOP from the repo root.
#
# COST MODEL, stated up front and printed before anything is created:
#   c2-standard-16 spot in us-central1 is indicatively ~$0.25–0.35/h (spot prices move; the
#   `create` step prints the live price if the API allows). --max-run-duration caps runtime by
#   construction; the VM POWERS ITSELF OFF when the job ends (vm_run.sh), so idle billing is
#   impossible by design rather than by vigilance; a STOPPED VM bills only its 20 GB disk
#   (~$0.05/day). Worst case ≈ 30 h × $0.35 ≈ $11 against an authorised $50.
#
# RESILIENCE:
#   - SPOT + --instance-termination-action=STOP: preemption stops the VM, the disk and the
#     checkpoint on it survive, `start` resumes at the last completed sweep (~6 min lost).
#   - The alignment checkpoints every sweep; vm_run.sh also uploads the checkpoint to a GCS
#     bucket every 15 min and on exit, so results survive even the loss of the disk.
#   - The startup script re-launches vm_run.sh on every boot, so `start` after a preemption
#     needs no further action.
#
# Every sizing choice cites a measurement: 16 vCPU not 64 (saturates ~12 threads); c2 for
# clock, since the alignment is integer-op bound on a 1.4 MB working set; AVX-512 irrelevant.
#
# Usage:  bash exploration/gcp/provision_m32.sh create    # price check, create, ship, launch
#         bash exploration/gcp/provision_m32.sh status    # log tail + uptime + cost so far
#         bash exploration/gcp/provision_m32.sh fetch     # pull results from the bucket
#         bash exploration/gcp/provision_m32.sh start     # after a preemption STOP
#         bash exploration/gcp/provision_m32.sh destroy   # delete VM + disk; keep the bucket
set -euo pipefail

PROJECT="gen-lang-client-0625573011"
REGION="us-central1"
ZONE="${REGION}-a"
NAME="mf-m32-align"
MACHINE="c2-standard-16"
IMAGE_FAMILY="debian-12"; IMAGE_PROJECT="debian-cloud"
MAX_RUN="30h"
RATE_INDICATIVE="0.30"          # $/h, spot, for the status estimate only — NOT a quote
REMOTE_DIR="/opt/scout"
BUCKET="mf-m32-align-${PROJECT}"

CKPT="exploration/scout_runs/S4_M32_align.ckpt"
SRC="exploration/dual_scale_scout_rs"

gc() { gcloud --project "$PROJECT" --quiet "$@"; }
ssh_() { gc compute ssh "$NAME" --zone="$ZONE" --command="$*"; }

case "${1:-create}" in
  create)
    [ -f "$CKPT" ] || { echo "no checkpoint at $CKPT — refusing to start from scratch on a paid machine"; exit 1; }
    echo "== checkpoint to ship: $(head -1 "$CKPT")"
    echo "== indicative cost: $MACHINE spot ~\$$RATE_INDICATIVE/h, hard cap $MAX_RUN → ≤ \$$(echo "$RATE_INDICATIVE * ${MAX_RUN%h}" | bc) worst case"
    gc compute machine-types describe "$MACHINE" --zone="$ZONE" --format="value(guestCpus,memoryMb)" 2>/dev/null \
      | awk '{printf "== machine: %s vCPU, %.0f GB\n", $1, $2/1024}' || true
    echo "== results bucket gs://$BUCKET (created if absent) =="
    gsutil ls -b "gs://$BUCKET" >/dev/null 2>&1 || gsutil mb -p "$PROJECT" -l "$REGION" "gs://$BUCKET"
    if gc compute instances describe "$NAME" --zone="$ZONE" >/dev/null 2>&1; then
      echo "== $NAME already exists; use 'start' or 'destroy' =="; exit 1
    fi
    echo "== creating $MACHINE SPOT in $ZONE =="
    gc compute instances create "$NAME" \
      --zone="$ZONE" --machine-type="$MACHINE" \
      --provisioning-model=SPOT --instance-termination-action=STOP \
      --max-run-duration="$MAX_RUN" \
      --image-family="$IMAGE_FAMILY" --image-project="$IMAGE_PROJECT" \
      --boot-disk-size=20GB --boot-disk-type=pd-standard \
      --scopes=storage-rw \
      --metadata-from-file=startup-script=exploration/gcp/vm_startup.sh \
      --labels=purpose=m32-alignment,tier=c,owner=mechanicafluidorum
    echo "== waiting for ssh =="
    for _ in $(seq 1 30); do ssh_ true 2>/dev/null && break; sleep 10; done
    echo "== shipping source + checkpoint =="
    ssh_ "sudo mkdir -p $REMOTE_DIR && sudo chown \$USER $REMOTE_DIR && echo $BUCKET > $REMOTE_DIR/bucket.txt"
    gc compute scp --zone="$ZONE" --recurse "$SRC/src" "$SRC/Cargo.toml" "$NAME:$REMOTE_DIR/"
    [ -f "$SRC/Cargo.lock" ] && gc compute scp --zone="$ZONE" "$SRC/Cargo.lock" "$NAME:$REMOTE_DIR/"
    gc compute scp --zone="$ZONE" "$CKPT" "$NAME:$REMOTE_DIR/S4_M32_align.ckpt"
    gc compute scp --zone="$ZONE" exploration/gcp/vm_run.sh "$NAME:$REMOTE_DIR/run.sh"
    echo "== launching (build ~3 min, then resumes from checkpoint; VM powers off when done) =="
    ssh_ "chmod +x $REMOTE_DIR/run.sh && nohup $REMOTE_DIR/run.sh > $REMOTE_DIR/run.out 2>&1 &"
    echo "== launched. 'bash $0 status' to follow. =="
    ;;
  status)
    ST=$(gc compute instances describe "$NAME" --zone="$ZONE" --format="value(status,lastStartTimestamp)" 2>/dev/null || echo "ABSENT")
    echo "== instance: $ST"
    if [[ "$ST" == RUNNING* ]]; then
      START=$(echo "$ST" | awk '{print $2}')
      H=$(python3 -c "from datetime import datetime,timezone;s=datetime.fromisoformat('$START'.replace('Z','+00:00'));print(round((datetime.now(timezone.utc)-s).total_seconds()/3600,2))")
      echo "== up ${H} h ≈ \$$(echo "$H * $RATE_INDICATIVE" | bc) at the indicative rate (not a bill)"
      ssh_ "tail -4 $REMOTE_DIR/align.log 2>/dev/null || tail -10 $REMOTE_DIR/run.out"
    else
      echo "== not running; latest in bucket:"; gsutil ls -l "gs://$BUCKET/" 2>/dev/null || true
    fi
    ;;
  fetch)
    mkdir -p exploration/scout_runs/gcp
    gsutil -m cp "gs://$BUCKET/*" exploration/scout_runs/gcp/ 2>/dev/null || echo "(bucket empty so far)"
    ls -l exploration/scout_runs/gcp/
    [ -f exploration/scout_runs/gcp/S4_M32_phases.txt ] && echo "== CONVERGED phases fetched ==" || echo "== not converged yet: checkpoint only =="
    ;;
  start)   gc compute instances start "$NAME" --zone="$ZONE"; echo "== startup script resumes from the checkpoint automatically ==" ;;
  destroy)
    gc compute instances delete "$NAME" --zone="$ZONE" 2>/dev/null || echo "(no instance)"
    echo "== VM and disk deleted. Bucket gs://$BUCKET kept (pennies); 'gsutil rm -r gs://$BUCKET' to remove."
    ;;
  *) echo "usage: $0 [create|status|fetch|start|destroy]"; exit 2 ;;
esac
