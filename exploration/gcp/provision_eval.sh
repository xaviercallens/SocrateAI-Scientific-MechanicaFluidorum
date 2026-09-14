#!/usr/bin/env bash
# TIER C — EXPLORATORY, NO CLAIMS.
#
# Provision a 16-vCPU SPOT instance for the EXACT EVALUATION of a phases file at a given M:
# `--align free --phases-start`, i.e. the class-set pass, the exact i128 |S| of the seed, and
# the exact greedy polish (one verification sweep when the seed is a strict local optimum).
# This is the M=64 job that is GCP-shaped (CORE_TAIL_CAP.md §4.3.10): ~35-40 h on the 8-core
# workstation, ~20 h here, and NOT on the critical path of the M=64 transient.
# Run ON THE LAPTOP from the repo root. The owner runs it (gcloud is denied to the session).
#
# COST MODEL, printed before anything is created: c2-standard-16 spot ~$0.25-0.35/h;
# --max-run-duration caps the runtime by construction; the VM POWERS ITSELF OFF when the job
# ends (vm_eval.sh); a STOPPED VM bills only its disk. Worst case 40 h x $0.35 = $14 < $50.
#
# RESILIENCE: SPOT + --instance-termination-action=STOP; the free path checkpoints every sweep
# (`--ckpt`) and resumes from it on every boot (startup script), so a preemption costs at most
# one pass; artifacts are uploaded to the bucket every 15 min and on exit.
#
# Usage:  bash exploration/gcp/provision_eval.sh create M PHASES_FILE   # e.g. 64 exploration/scout_runs/S5_M64_phases.txt
#         bash exploration/gcp/provision_eval.sh status
#         bash exploration/gcp/provision_eval.sh fetch
#         bash exploration/gcp/provision_eval.sh start        # after a preemption STOP
#         bash exploration/gcp/provision_eval.sh destroy
set -euo pipefail

PROJECT="gen-lang-client-0625573011"
REGION="us-central1"
ZONE="${REGION}-a"
NAME="mf-eval"
MACHINE="c2-standard-16"
IMAGE_FAMILY="debian-12"; IMAGE_PROJECT="debian-cloud"
MAX_RUN="40h"
RATE_INDICATIVE="0.30"          # $/h, spot, for the status estimate only — NOT a quote
REMOTE_DIR="/opt/scout"
BUCKET="mf-eval-${PROJECT}"
SRC="exploration/dual_scale_scout_rs"

gc() { gcloud --project "$PROJECT" --quiet "$@"; }
ssh_() { gc compute ssh "$NAME" --zone="$ZONE" --command="$*"; }

case "${1:-}" in
  create)
    M="${2:?M}"; PH="${3:?phases file}"
    [ -f "$PH" ] || { echo "no phases file at $PH"; exit 1; }
    head -1 "$PH" | grep -q "M=$M\$" || { echo "phases header does not say M=$M"; exit 1; }
    echo "== job: exact evaluation of $PH at M=$M ($(($(wc -l < "$PH") - 1)) signs)"
    echo "== indicative cost: $MACHINE spot ~\$$RATE_INDICATIVE/h, hard cap $MAX_RUN → ≤ \$$(echo "$RATE_INDICATIVE * ${MAX_RUN%h}" | bc) worst case"
    gc compute machine-types describe "$MACHINE" --zone="$ZONE" --format="value(guestCpus,memoryMb)" 2>/dev/null \
      | awk '{printf "== machine: %s vCPU, %.0f GB\n", $1, $2/1024}' || true
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
      --labels=purpose=exact-eval,tier=c,owner=mechanicafluidorum
    echo "== waiting for ssh =="
    for _ in $(seq 1 30); do ssh_ true 2>/dev/null && break; sleep 10; done
    echo "== shipping source + phases =="
    ssh_ "sudo mkdir -p $REMOTE_DIR && sudo chown \$USER $REMOTE_DIR && echo $BUCKET > $REMOTE_DIR/bucket.txt && echo $M > $REMOTE_DIR/M.txt"
    gc compute scp --zone="$ZONE" --recurse "$SRC/src" "$SRC/Cargo.toml" "$NAME:$REMOTE_DIR/"
    [ -f "$SRC/Cargo.lock" ] && gc compute scp --zone="$ZONE" "$SRC/Cargo.lock" "$NAME:$REMOTE_DIR/"
    gc compute scp --zone="$ZONE" "$PH" "$NAME:$REMOTE_DIR/seed_phases.txt"
    gc compute scp --zone="$ZONE" exploration/gcp/vm_eval.sh "$NAME:$REMOTE_DIR/run.sh"
    echo "== launching (build ~3 min; VM powers off when done) =="
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
      ssh_ "tail -4 $REMOTE_DIR/eval.log 2>/dev/null || tail -10 $REMOTE_DIR/run.out"
    else
      echo "== not running; latest in bucket:"; gsutil ls -l "gs://$BUCKET/" 2>/dev/null || true
    fi
    ;;
  fetch)
    mkdir -p exploration/scout_runs/gcp
    gsutil -m cp "gs://$BUCKET/*" exploration/scout_runs/gcp/ 2>/dev/null || echo "(bucket empty so far)"
    ls -l exploration/scout_runs/gcp/
    grep -h "initial exact\|sweep .* done" exploration/scout_runs/gcp/eval.log 2>/dev/null || echo "== no result lines yet =="
    ;;
  start)   gc compute instances start "$NAME" --zone="$ZONE"; echo "== startup script resumes from the checkpoint automatically ==" ;;
  destroy)
    gc compute instances delete "$NAME" --zone="$ZONE" 2>/dev/null || echo "(no instance)"
    echo "== VM and disk deleted. Bucket gs://$BUCKET kept (pennies); 'gsutil rm -r gs://$BUCKET' to remove."
    ;;
  *) echo "usage: $0 create M PHASES | status | fetch | start | destroy"; exit 2 ;;
esac
