---
name: resilient-job
description: Design or review a long-running, resumable, or cloud-hosted computation so it survives interruption without silent data loss and without re-spending compute on a false failure. Use before launching anything that will run unattended for more than a few minutes, and before trusting any "this job failed" report from one. Adapted from a real three-bug incident chain (2026-09-15..17): a quota refusal, an empty-bucket failure, and two verification-tooling bugs that each quarantined a fully-converged result and triggered a needless full restart.
tools: Read, Write, Edit, Bash
---

# Resilient job design — checklist, drawn from a real incident chain

This encodes what the M=64 exact-evaluation job on GCP needed, discovered the hard way across
three separate failures, none of which were in the actual computation
(`exploration/gcp/vm_eval.sh`, `exploration/dual_scale_scout_rs`, `LL-29`, `LL-30`, `LL-31`).
Apply it to *any* job that will run unattended long enough that you will not be watching it the
whole time — a cloud VM, a background batch, a multi-hour local process.

## 1. Checkpoint the actual state, inside every expensive pass, not only between them

A computation with several sequential expensive phases must be able to resume **inside** each
one, not only at phase boundaries. The first design here checkpointed only between completed
sweeps of a three-pass algorithm; the first pass alone could run for hours, and a preemption
during it would have lost everything. Checkpoint on a time cadence within every pass that can
itself run long.

Make the checkpoint **self-verifying** (a trailing integrity hash over the whole saved state, not
just a length or a magic number) and **durable against a torn write**: write to a temp file,
`fsync` it, then atomically rotate the previous save to a `.prev` fallback before renaming the
new one into place. A load that fails integrity on the primary file must fall back to `.prev`
automatically, and a load that fails on *both* must refuse to proceed silently — exit loudly with
a distinct status, never fall back to starting over without saying so.

**Test this specifically, by killing the real process** after every $k$-th checkpoint save, for
several values of $k$, across every phase the state machine has — including the phase that
happens right after the computation converges, which is the state a preemption immediately after
success, or any retry after any other failure, lands you in, and the one a naive kill-and-resume
test schedule tends to never produce by accident (`LL-29`). Confirm the resumed output is
byte-identical (or otherwise exactly equivalent) to an uninterrupted reference run, not merely
"close" or "plausible."

## 2. The job's own log is not the checkpoint — do not trust it the same way

A diagnostic log is useful and should be kept, but do not `fsync` it on every line (that is
wasteful) and do not assume it is pristine text. An abrupt stop (a hard preemption, not a clean
shutdown) can leave a torn write — including stray null bytes — at the exact boundary where one
attempt's output stops and the next one's begins. Any tool that reads this log to make a
succeed/fail decision must be proofed against that: a plain `grep` silently treats a file
containing a null byte as binary and matches nothing, converting a real success into a reported
failure with no error message at all. Force text search explicitly (`grep -a`, or read the bytes
and filter nulls yourself) at every place a log is parsed for a verdict, and say so in a comment
so the next editor doesn't drop it.

## 3. The success/failure verdict needs its own controls

Before trusting a runner's own "this converged" or "this failed" determination, prove the
determination logic actually works, the same way you would prove a scientific control works
(`LL-19`, `LL-29`):

- **Positive control.** Run the happy path end to end and confirm the correct verdict.
- **Negative control, demonstrated to fire correctly.** Feed it a genuinely corrupt input (a
  truncated file, a tampered checksum) and confirm it reports failure with the right diagnosis —
  not just that it fails, but that it fails *for the stated reason*.
- **The state your own recovery mechanism will actually produce.** If preemption-and-resume is
  possible, explicitly construct "a fresh process launched against an already-finished
  checkpoint" and confirm it reaches the finished state cleanly, with no spurious failure. This
  is the single case both real bugs in this section's origin incident hid in, because no earlier
  test happened to produce it.

## 4. A "discard as unusable, start over" action needs proof of corruption, not proof a reader failed (`LL-30`)

If a verification step is about to declare state unusable and trigger an expensive restart,
that is a costly, hard-to-reverse action and deserves its own diagnostic step first: read the
artefact directly, with a *different* tool than the one that just failed on it (a byte-level
read in a language with no binary-detection heuristics, not another invocation of the same
`grep`). If the data is actually intact, the bug is in the reader, and the fix is there — not in
accepting the recompute as the price of "safety."

## 5. Recovery should target the backed-up value, not blindly re-spend the resource that produced it (`LL-31`)

If a result is independently mirrored somewhere the failing instance cannot also corrupt (a
storage bucket, a separate host, version control), a verification failure on the *primary* copy
is not evidence the *result* is gone. Once the reading bug (if any) is fixed and proven against a
reproduction of the exact failure — never trust a fix you haven't watched fail first — recovering
the backed-up state and re-running only the cheap "load, verify, finalize" steps (locally, if
that's cheaper than another cloud instance) can finish the job in seconds instead of hours. Only
destroy or discard the instance that began an unnecessary recompute once the recovery is
independently confirmed.

## 6. Telemetry: make "is it actually alive" answerable without logging in

Three independent, low-cost channels, each useful when the others are unavailable:
- **Machine-readable status on the instance/process record itself** (cloud guest attributes, a
  local status file), pollable without a login — status, a heartbeat timestamp, and progress
  (phase, fraction complete, an ETA derived from a measured rate, not a guessed one).
  A heartbeat older than a few missed intervals means the process is not reporting, whether or
  not the instance itself is still marked "running" — check both.
- **The process's own console/serial output**, for the failure that happens before any of your
  own telemetry code has run.
- **A results store** (bucket, shared filesystem) that receives partial artifacts periodically,
  not only on success — so a failure mid-run still leaves something to diagnose from.

## 7. Quantify cost from the job's own clock before trusting an estimate scaled from elsewhere

Do not extrapolate a wall-time estimate from a different problem size or a different machine
without labelling it as an extrapolation (`LL-22`). Time each expensive phase directly, with the
production binary, on a real (or realistically edited) checkpoint at several positions, before
committing cloud budget to the full run. State the machine-translation factor (same vs. different
core count/clock) explicitly, and replace the estimate with the job's own measured rate as soon
as it is available (typically within the first 10–30 minutes of a real run).

## What this is not

This is not a cloud-specific checklist — everything above applies to any long-running resumable
process, local or remote. It is also not a substitute for testing the actual computation; it
assumes that part is already correct and is entirely about not losing or misreporting a correct
answer to infrastructure failure. Origin: `exploration/gcp/{vm_eval.sh,provision_eval.sh,
test_ckpt_resilience.sh,test_runner_local.sh}`, `LL-29`, `LL-30`, `LL-31`.
