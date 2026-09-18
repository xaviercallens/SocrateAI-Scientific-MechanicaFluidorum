---
name: publish-gate
description: Gate any permanent, outward-facing artifact — a DOI-bearing archive (Zenodo), a dataset card, a release attached to a paper — behind checks that neither verification gate performs. Use before minting a DOI, before pushing to a public dataset host, and before any "publish" step that cannot be undone. Drawn from two real episodes on 2026-09-17/18: a paper nearly archived with a placeholder author line on every page, and a sister project's upload script that would have re-published already-withdrawn claims under a permanent identifier.
tools: Read, Bash, Grep
---

# Publish gate — what must be true before an identifier becomes permanent

A DOI cannot be withdrawn; it can only be superseded by a new version with a tombstone on the
old one. A dataset card served under a real name is read by people who never see the
correction. That makes "publish" the one action in this programme with a blast radius larger
than a bad commit, and it needs a gate of its own — the two verification gates certify that
proofs are valid and identities hold, and say nothing about whether the artifact about to be
archived is the one you think it is.

Origin incidents, both within twenty-four hours of each other:

- **This repository, 2026-09-18.** The external paper was one flag away from a permanent DOI
  with the running head reading `AUTHOR LIST AND AFFILIATIONS TO BE SUPPLIED` on every page,
  and with a creator name in the metadata that had been *inferred* from a GitHub handle rather
  than supplied by the owner. The inference was wrong: the author of record is an organisation.
  Caught by the deposit script's refusal to publish without an explicit second flag, which
  bought the pause in which the placeholder was noticed (`scripts/zenodo_deposit.sh`).
- **Sister project, 2026-09-15 (`OpenAI-NSE-Verification/CHANGELOG.md`, v5.1.0).** The
  Zenodo push script still carried the title, description and file list of a *withdrawn*
  framing — claims the project had already retracted. "Had this been run unmodified, it would
  have re-published already-withdrawn claims under a permanent DOI." Caught by reading the
  script before running it. The same project's Hugging Face dataset was found *already* serving
  a retracted paper and a known unit bug, live, under a real name.

## The checklist — every item, in order, before the irreversible step

### 1. Author of record: supplied, never inferred

The creator field is the one piece of metadata that outlives every correction. It must come
from the owner in their own words — name, organisation, affiliation — and the paper's own
`\author` / `\address` must carry the same text. Grep the compiled PDF's text for
`to be supplied`, `placeholder`, `TODO`, `XXX`, and for the running-head string, before
anything else. An inferred name (from an email, a handle, a commit author) is a defect, not a
default.

### 2. The artifact is the tagged one, byte for byte

Archive a **tagged release**, never a working tree. Confirm:
- the PDF being uploaded is the PDF built from the tagged `.tex` (rebuild and `sha256sum`, or
  compare against the committed PDF at the tag);
- every file in the upload set matches the tag (the sister project's release check: every
  file's checksum against the tagged commit — `66/66` at v5.6.0);
- the source tarball is `git archive <tag>`, so it cannot include uncommitted edits.

### 3. Both gates pass at that tag

Run `scripts/verify.sh` at the tagged commit and require exit 0. A deposit is a claim about
what the code does; the DOI inherits every unverified sentence. The deposit script enforces
this for production publishes; do not bypass it by publishing from the web UI.

### 4. Metadata describes the artifact, not a previous one

Read the metadata file (`.zenodo.json`, the dataset card, the push script's constants) end to
end **against the current paper's abstract and status notes**. Specifically:
- no withdrawn claim survives in the description (grep the changelog's "withdrawn" list
  against the metadata text);
- version string matches the tag;
- related identifiers (concept DOI, repository URL, prior version) resolve;
- license field is present **only if** a `LICENSE` file exists in the tree — do not assert
  a license the repository has not adopted.

### 5. If the identifier is cited inside the artifact, update in place

A pre-reserved DOI printed inside the PDF binds the deposit to **that** deposition. A fresh
deposition mints a *different* DOI and silently invalidates the self-reference in the archived
document. Update the existing draft (`--deposition ID`), replace files by name, and **prune
superseded files** (a renamed tarball leaves its predecessor sitting in the published record).

### 6. Draft first; publish is a separate, explicit decision

Create the draft, read it back through the API (not the script's own success line), confirm
`state: unsubmitted`, file list, sizes, creators, version. Only then publish, with the explicit
flag, as its own step. Never let publish ride along with upload.

### 7. Verify the live record anonymously

After publishing, fetch the public record **without** credentials and compare DOI, title,
creators, version, file names and sizes against what you intended. The script's own
`PUBLISHED` line is a self-report (`LL-2`); the anonymous fetch is the evidence.

### 8. Secrets that touched a transcript are burned

If a token was pasted into a chat, a shell history, or a log to make the deposit happen, it is
now stored somewhere it should not be. Say so in the report and ask for rotation. Do not
quietly keep using it.

### 9. Superseded public copies are found and labelled

Search every public host the project has ever used (Zenodo versions, Hugging Face, a second
"deploy" script pointed at a different repo) for earlier copies of withdrawn material. Label
them with the withdrawal and a pointer to the current version — or delete them if the host
permits — and record what remains live that you could not remove.

## Definition of done

- [ ] Author of record supplied by the owner, present in both metadata and document.
- [ ] Upload set matches the tagged release by checksum; tarball is `git archive <tag>`.
- [ ] `scripts/verify.sh` exit 0 at the tag.
- [ ] Metadata read against the changelog's withdrawn list; version string matches the tag.
- [ ] Existing draft updated in place when a DOI is already printed in the artifact; stale
      files pruned.
- [ ] Draft read back through the API before publishing; publish is a separate step.
- [ ] Live record verified by an anonymous fetch.
- [ ] Any exposed credential reported for rotation.
- [ ] Earlier public copies located and labelled.

## What this skill must never do

Never publish because the user said "push to Zenodo" while an item above is open. State which
item is open, do everything reversible up to the draft, and stop. The user can override in one
sentence; a DOI cannot be un-minted in any number of them.

Origin: `scripts/zenodo_deposit.sh`, `docs/paper/REVIEW.md`,
`OpenAI-NSE-Verification/CHANGELOG.md` (v5.0.0–v5.6.0), `LL-2`, `LL-23`.
