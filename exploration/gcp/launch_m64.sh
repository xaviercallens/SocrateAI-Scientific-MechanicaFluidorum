#!/usr/bin/env bash
# TIER C — EXPLORATORY, NO CLAIMS. One-shot launcher for the M=64 exact evaluation on GCP.
# Run from the repo root (owner-run: gcloud is denied to the agent session):
#
#   bash exploration/gcp/launch_m64.sh                 # uses exploration/scout_runs/S5_M64_phases.txt
#   bash exploration/gcp/launch_m64.sh --fresh         # recreate even if a bucket checkpoint exists
#
# What it does, and what it refuses to do:
#   1. checks gcloud login, the seed file, and the job's state in the bucket:
#        result already there        -> stops (nothing to do; use `provision_eval.sh fetch 64`)
#   2. deals with an existing instance named mf-eval:
#        RUNNING / STAGING / ...     -> stops: a job may be live, it is never touched
#        TERMINATED + bucket ckpt    -> RESUMES that job (`provision_eval.sh resume`) unless --fresh
#        TERMINATED, no checkpoint   -> saves its serial console (the diagnosis), then deletes it
#   3. preflight: regional quota per machine type, bucket (prints the chosen machine and cost)
#   4. create: bundle (build + local smoke test + sha256), upload, spot VM with zone fallback
#   5. waits until the VM ITSELF reports (guest attribute mf/status): RUNNING -> prints the
#      monitoring schedule as clock times; FAILED_* -> prints the runner's lines and exits 1.
#
# Measured time to complete (exploration/gcp/test_results/2026-09-15_calibration_M64.txt):
# 16.6 h on a 4-core/8-thread laptop for one sweep; c2-standard-8 (same topology, faster cores)
# estimated 11-17 h; 29.8 h laptop-equivalent if a second sweep is needed. Cost ~$2-3 (one sweep).
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO"
M=64
SEED="exploration/scout_runs/S5_M64_phases.txt"
FRESH=0
for a in "$@"; do
  case "$a" in
    --fresh) FRESH=1 ;;
    -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
    *) SEED="$a" ;;
  esac
done
P="exploration/gcp/provision_eval.sh"
PROJECT="gen-lang-client-0625573011"
NAME="${MF_NAME:-mf-eval}"
BUCKET="mf-eval-${PROJECT}"
PFX="m${M}"
say() { echo "== $(date '+%H:%M:%S') $*"; }
g() { gcloud --project "$PROJECT" --quiet "$@"; }

say "1/5 checks"
command -v gcloud >/dev/null 2>&1 || { echo "gcloud is not installed"; exit 1; }
acct=$(gcloud config get-value account 2>/dev/null || true)
[ -n "$acct" ] || { echo "gcloud has no active account: run 'gcloud auth login'"; exit 1; }
say "account $acct, project $PROJECT"
[ -f "$SEED" ] || { echo "seed file $SEED not found"; exit 1; }
head -1 "$SEED" | grep -qx "# scout adversarial phases M=$M" || { echo "$SEED is not an M=$M phases file"; exit 1; }
if gcloud storage ls "gs://$BUCKET/$PFX/out/DONE" >/dev/null 2>&1; then
  say "gs://$BUCKET/$PFX/out/DONE exists: this job has already finished. Get it with: bash $P fetch $M"
  exit 0
fi
have_ckpt=0
if gcloud storage ls "gs://$BUCKET/$PFX/ckpt/eval.ckpt" >/dev/null 2>&1; then have_ckpt=1; say "a checkpoint for $PFX exists in the bucket"; fi

say "2/5 existing instance"
zone=$(g compute instances list --filter="name=$NAME" --format="value(zone.basename())" 2>/dev/null | head -1 || true)
if [ -n "$zone" ]; then
  st=$(g compute instances describe "$NAME" --zone="$zone" --format="value(status)")
  say "$NAME exists in $zone: $st"
  case "$st" in
    TERMINATED|STOPPED|SUSPENDED)
      if [ "$have_ckpt" = 1 ] && [ "$FRESH" = 0 ]; then
        say "it holds a job with a checkpoint: RESUMING it instead of recreating (use --fresh to recreate)"
        bash "$P" resume
        T0=$(date +%s); RESUMED=1
      else
        say "saving its serial console before deleting it (the diagnosis of how it ended)"
        bash "$P" logs all 2>/dev/null | head -1 || true
        bash "$P" destroy
      fi
      ;;
    *)
      say "$NAME is $st: a job may be live -- not touching it. Check it with: bash $P status $M"
      exit 1
      ;;
  esac
fi

if [ "${RESUMED:-0}" = 0 ]; then
  say "3/5 preflight (quota, bucket, machine type)"
  machine=$(bash "$P" preflight "$M" "$SEED")
  say "machine: $machine"
  say "4/5 create (bundle -> bucket -> spot VM)"
  bash "$P" create "$M" "$SEED"
  T0=$(date +%s)
fi

say "5/5 waiting for the VM to report (first report ~2-4 min after boot; giving up after 10 min)"
st=""
for _ in $(seq 1 30); do
  zone=$(g compute instances list --filter="name=$NAME" --format="value(zone.basename())" 2>/dev/null | head -1 || true)
  if [ -n "$zone" ]; then
    st=$(g compute instances get-guest-attributes "$NAME" --zone="$zone" --query-path=mf/status --format="value(value)" 2>/dev/null || true)
    case "$st" in
      RUNNING|DONE) say "the VM reports: $st"; break ;;
      FAILED_*)
        say "the VM reports $st -- its diagnosis:"
        bash "$P" status "$M" || true
        bash "$P" logs || true
        say "it holds 15 min before powering off; fix the cause, then rerun this launcher"
        exit 1
        ;;
      "") ;;
      *) say "the VM reports: $st" ;;
    esac
  fi
  sleep 20
done
case "$st" in
  RUNNING|DONE) ;;
  *) say "no RUNNING report within 10 min (last: '${st:-none}'). Look at: bash $P logs all"; exit 1 ;;
esac
bash "$P" status "$M" || true

at() { date -d "@$((T0 + $1))" '+%a %d %b %H:%M'; }
mkdir -p exploration/scout_runs/gcp
sched="exploration/scout_runs/gcp/${PFX}_monitor_schedule.txt"
cat <<EOF | tee "$sched"

MONITORING SCHEDULE -- M=$M exact evaluation, launched $(at 0)
command for every check:   bash $P status $M

  $(at 600)   T0+10min  RUNNING, phase classes/init, heartbeat < 2 min old
                              (not so -> bash $P logs)
  $(at 1800)   T0+30min  phase init with a % and an ETA. Real speed of this VM:
                              init total = ETA / (1 - fraction done);  job total ~ init total x 4.8
  $(at 12600)   T0+3.5h   phase sweep, sweep=1, flips=0   (flips > 0 -> a 2nd sweep, +10-13 h)
  every 4-6 h                 heartbeat fresh, sweep % rising.  Instance TERMINATED without DONE
                              = preempted: bash $P resume   (loses at most ~2 min of work)
  $(at 39600) -> $(at 61200)
                              EXPECTED DONE (one sweep, T0+11h..17h)
                              then: bash $P fetch $M  &&  bash $P destroy
  $(at 72000) -> $(at 108000)
                              if a second sweep was needed (T0+20h..30h)
  $(at 172800)   T0+48h    hard cap: the VM stops itself (the bucket keeps the checkpoint)

cost: ~\$0.18/h indicative -> ~\$2-3 for one sweep, < \$9 at the cap
EOF
say "schedule saved to $sched"
