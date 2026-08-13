#!/usr/bin/env python3
"""Stage-0 gate component: LEDGER consistency check + single-active-file lint.

Implements the two static checks listed in SPEC.md §5.1 item 3 ("single-active-file lint
(§7.4); LEDGER consistency check (every Tier A/B entry maps to a passing artifact)") and the
campaign-level DoD item in PLAN.md §7 ("LEDGER.md audit: every row maps to a passing artifact;
no orphan claims"). Neither existed before 2026-08-13.

WHAT THIS CHECKS (and, as importantly, what it does not)

  C1 FILE REFERENCES. Every repo-relative path cited in LEDGER.md must exist on disk. This is
     the check that catches a ledger row surviving a file rename or deletion.

  C2 LEAN NAME REFERENCES. Every Lean identifier cited in a Tier A ROW of LEDGER.md must be
     declared somewhere in lean_src/. "Declared" deliberately includes `theorem`, `lemma`,
     `def`, `noncomputable def`, `abbrev`, `instance`, `structure`, `class`, and CLASS FIELDS
     (`  field_name : ...` inside a class body) -- the last of these matters and was found
     empirically: LEDGER.md's Tier A table cites `resonance_law`, which is a class field of
     `CosmicWave` in CallensDualScale.lean, not a standalone theorem. A checker that only
     matched `theorem|lemma|def` would report it as an orphan. That false positive is exactly
     the failure mode this file is designed around.

  C3 SINGLE-ACTIVE-FILE LINT (SPEC §7.4). No versioned duplicate source files (`*_v2.*`,
     `*_final.*`, `*_old.*`, `*_copy.*`) may exist in the active trees. `git` history is the
     archive. One deliberate exception is allowlisted: `docs/SPEC_v0.1_original.md`, the frozen
     record of the received specification, which SPEC.md itself references by that exact name.

DELIBERATELY NOT CHECKED (declared, so nobody reads more assurance into a green run than is
there):
  * That a cited theorem PROVES what its ledger prose says it proves. That is statement
    adequacy -- reserved to human audit by SPEC.md §0, and not mechanisable here.
  * That the artifact currently COMPILES or PASSES. That is what verify.sh's Gate 1 and Gate 2
    already do; this script is a static cross-reference check and would be redundant, and much
    slower, if it re-ran them.
  * Prose backticks. The Tier A name check applies only to identifiers appearing in the
    `Formal name` position of a table row, not to every backticked token in the file --
    LEDGER.md's prose legitimately backticks things like `a`, `k_n`, `B`, `sorryAx`, and the
    names of RETIRED claims (`alpha_prime_pos`, `global_well_posedness_regularized_shell`)
    which are supposed to be absent from lean_src/. Matching those would make the checker
    useless by drowning real findings in noise.

NEGATIVE CONTROL (PLAN.md §2: "a checker that cannot fail is not a checker"). Run with
`--self-test`: three synthetic ledgers are checked, each of which MUST be rejected -- a
dangling file path, a dangling Lean name, and a banned versioned filename. If any of them is
accepted, this script exits non-zero and says so. The self-test runs against synthetic inputs
in a temp dir and never touches the real repo.

Exit codes: 0 = all checks pass; 1 = a real inconsistency was found; 2 = self-test failed.
"""

import os
import re
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Paths cited in the ledger are matched only when they look like repo-relative paths under a
# known top-level directory, so prose like `Fin n -> K` is never mistaken for a path.
PATH_DIRS = ("lean_src", "tests", "symbolic", "exploration", "data", "docs", "scripts")
PATH_RE = re.compile(r"`((?:%s)/[A-Za-z0-9_./-]+)`" % "|".join(PATH_DIRS))

# Declaration forms that count as "this identifier exists in lean_src/".
DECL_RE_TMPL = (
    r"(?:^|\s)(?:theorem|lemma|def|abbrev|instance|structure|class|example)\s+{name}\b"
    r"|(?:^|\s)noncomputable\s+def\s+{name}\b"
    r"|^\s+{name}\s*:"          # class field / structure field
    r"|^\s+{name}\s*:="         # instance field assignment
)

BANNED_SUFFIX_RE = re.compile(r".*(_v[0-9]+|_final|_old|_copy)\.(lean|py|md)$")
LINT_ALLOWLIST = {"docs/SPEC_v0.1_original.md"}
LINT_DIRS = ("lean_src", "tests", "symbolic", "exploration", "scripts", "docs")


def lean_sources(repo):
    out = {}
    d = os.path.join(repo, "lean_src")
    if not os.path.isdir(d):
        return out
    for fn in sorted(os.listdir(d)):
        if fn.endswith(".lean"):
            with open(os.path.join(d, fn), encoding="utf-8") as fh:
                out[fn] = fh.read()
    return out


def name_declared(name, sources):
    pat = re.compile(DECL_RE_TMPL.format(name=re.escape(name)), re.MULTILINE)
    return any(pat.search(text) for text in sources.values())


def tier_a_names(ledger_text):
    """Identifiers in the 'Formal name' column of Tier A table rows.

    Tier A tables in LEDGER.md have the shape `| claim | \\`name\\` | ... |`, sometimes with
    several comma-separated names in that cell. Rows under the 'Retired / corrected claims'
    heading are excluded by construction: those name things that are SUPPOSED to be gone.
    """
    # Cut the retired section off before scanning.
    cut = ledger_text.split("## Retired / corrected claims")[0]
    names = set()
    for line in cut.splitlines():
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 2:
            continue
        # The formal-name cell is the one made (almost) entirely of backticked identifiers.
        for cell in cells[1:]:
            toks = re.findall(r"`([A-Za-z_][A-Za-z0-9_']*)`", cell)
            if not toks:
                continue
            stripped = re.sub(r"`[^`]*`", "", cell)
            stripped = stripped.replace(",", "").replace("(+ tighter", "").replace(")", "")
            stripped = stripped.replace("and", "").replace("via", "").strip()
            if stripped in ("", "+", "-", "—"):
                names.update(toks)
    # Structural noise that is never a Lean identifier.
    return {n for n in names if n not in {"example", "instances", "ibid"}}


def check_paths(repo, ledger_text):
    missing = []
    for m in sorted(set(PATH_RE.findall(ledger_text))):
        target = os.path.join(repo, m.rstrip("/"))
        if not os.path.exists(target):
            missing.append(m)
    return missing


def check_names(repo, ledger_text):
    sources = lean_sources(repo)
    if not sources:
        return ["<no lean_src/*.lean found>"]
    return [n for n in sorted(tier_a_names(ledger_text)) if not name_declared(n, sources)]


def check_lint(repo):
    offenders = []
    for d in LINT_DIRS:
        root = os.path.join(repo, d)
        if not os.path.isdir(root):
            continue
        for dirpath, _dirnames, filenames in os.walk(root):
            for fn in filenames:
                full = os.path.join(dirpath, fn)
                rel = os.path.relpath(full, repo)
                if rel in LINT_ALLOWLIST:
                    continue
                if BANNED_SUFFIX_RE.match(fn):
                    offenders.append(rel)
    return sorted(offenders)


def run(repo, ledger_path, verbose=True):
    with open(ledger_path, encoding="utf-8") as fh:
        text = fh.read()
    missing_paths = check_paths(repo, text)
    missing_names = check_names(repo, text)
    lint = check_lint(repo)
    if verbose:
        print(f"  C1 file references : {'FAIL' if missing_paths else 'ok'} "
              f"({len(set(PATH_RE.findall(text)))} cited)")
        for p in missing_paths:
            print(f"       MISSING FILE: {p}")
        print(f"  C2 Tier A names    : {'FAIL' if missing_names else 'ok'} "
              f"({len(tier_a_names(text))} cited)")
        for n in missing_names:
            print(f"       UNDECLARED IN lean_src/: {n}")
        print(f"  C3 versioned-file lint: {'FAIL' if lint else 'ok'}")
        for f in lint:
            print(f"       BANNED VERSIONED FILE: {f}")
    return not (missing_paths or missing_names or lint)


def self_test():
    """Three synthetic ledgers, each of which MUST be rejected."""
    print("== self-test (each case MUST be rejected) ==")
    ok = True
    with tempfile.TemporaryDirectory() as td:
        os.makedirs(os.path.join(td, "lean_src"))
        with open(os.path.join(td, "lean_src", "Real.lean"), "w") as fh:
            fh.write("theorem genuine_thm : True := trivial\n")

        cases = {
            "dangling file path":
                "| c | `genuine_thm` | x |\n\nSee `lean_src/DoesNotExist.lean` here.\n",
            "dangling Lean name":
                "| c | `no_such_theorem_anywhere` | x |\n",
        }
        for label, content in cases.items():
            p = os.path.join(td, "L.md")
            with open(p, "w") as fh:
                fh.write(content)
            accepted = run(td, p, verbose=False)
            print(f"  {label:24s}: {'ACCEPTED (BUG!)' if accepted else 'rejected as required'}")
            ok = ok and not accepted

        # banned versioned file
        p = os.path.join(td, "L.md")
        with open(p, "w") as fh:
            fh.write("| c | `genuine_thm` | x |\n")
        bad = os.path.join(td, "lean_src", "Thing_v2.lean")
        with open(bad, "w") as fh:
            fh.write("-- archived copy\n")
        accepted = run(td, p, verbose=False)
        print(f"  {'banned versioned file':24s}: "
              f"{'ACCEPTED (BUG!)' if accepted else 'rejected as required'}")
        ok = ok and not accepted
        os.remove(bad)

        # positive control: the clean case must be ACCEPTED, else the checker is vacuous
        accepted = run(td, p, verbose=False)
        print(f"  {'clean case (control)':24s}: "
              f"{'accepted as required' if accepted else 'REJECTED (BUG!)'}")
        ok = ok and accepted

    if not ok:
        print("SELF-TEST FAILED — the checker does not reliably fail. Aborting.")
        sys.exit(2)
    print("  self-test: all cases behaved as required\n")


def main():
    if "--self-test" in sys.argv:
        self_test()
        return
    self_test()
    print("== LEDGER consistency check + single-active-file lint ==")
    ledger = os.path.join(REPO, "LEDGER.md")
    if run(REPO, ledger):
        print("LEDGER GATE: PASS (all cited artifacts exist; no orphan Tier A names; "
              "no banned versioned files)")
    else:
        print("LEDGER GATE: FAIL")
        sys.exit(1)


if __name__ == "__main__":
    main()
