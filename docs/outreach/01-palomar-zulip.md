# Draft: Palomar Zulip post

**Venue:** <https://leanprover.zulipchat.com/#narrow/channel/621638-Palomar>
**Topic name:** `An adversarial corpus for check (b)`
**Post as:** yourself, signed.
**Status:** ready to paste. Do not post until the two blockers below are cleared.

## Blockers, both now cleared as of 2026-09-18

- [x] `LL.md` in the verification repository rewritten; the terminology table, the
      link-withholding rules and the agree-immediately rule are gone, and their removal is
      itemised in the file and in that repository's changelog.
- [x] The Elenchus repository no longer names the proprietary sibling anywhere.
- [ ] **Do not link the verification repository in this post.** Its producer, verifier and sole
      reviewer are the same party, so "independently verified" is not a description available to
      it. Link only Elenchus.

## Why this venue and this framing

Palomar is Tao's own project, announced 18 August 2026, and the Zulip channel is where he said
discussion happens. Its check (b) is an LLM judging whether an informal description matches the
formal statement. That is exactly what the corpus is built to stress, so this is a contribution to
an active project rather than a request for attention. The post offers something and asks nothing.

The last paragraph is not optional. It is what stops the message being filed with every other
unsolicited Navier–Stokes message.

---

## The text

Hello. I want to offer something rather than ask for something.

Check (b) is the one I would most want a test set for. Over the past month I have been running two
small Lean-based audit efforts, and I kept hitting the same failure from different directions: a
development that passes every mechanical check and establishes nothing. I have reduced the cases to
an eight-entry corpus with known answers. Six are defects. Two are deliberate false-positive
controls, because a detector that flags everything is not a detector.

The entry I would point at first, reduced to a minimal fixture:

```lean
/-- The Galerkin solution remains in H¹ with bounded norm for all time,
    given the certificate's invariant bounds, contraction, residual,
    H¹ bound, enstrophy bound and spectral decay. -/
theorem regularity (InvariantBounds Contraction Residual H1Bound Enstrophy Decay : Prop)
    (h_inv : InvariantBounds) (h_ctr : Contraction) (h_res : Residual)
    (h_h1 : H1Bound) (h_ens : Enstrophy) (_h_decay : Decay) :
    InvariantBounds ∧ Contraction ∧ Residual ∧ H1Bound ∧ Enstrophy :=
  ⟨h_inv, h_ctr, h_res, h_h1, h_ens⟩
```

It is sorry-free. Its footprint is exactly `{propext, Classical.choice, Quot.sound}`. It assumes
five conjuncts and concludes their conjunction. There is no solution and no H¹ anywhere in the
statement. I found this shape in the wild, not constructed for the purpose.

The other five defects are: a predicate defined as `Prop := True` carrying its whole claim in a
docstring; two theorems concluding `True` whose names claim an implication and a uniqueness result;
a theorem that is sorry-free in its own source and inherits `sorryAx` through a lemma; a file that
compiles cleanly with no `#print axioms` in it at all; and a numerical control whose every input is
a dyadic rational, so it passes with the rounding safety mechanism it tests deleted.

That fifth one is in the corpus because it was ours. Our own gate scored a file of that shape as
"0 theorems, all footprints clean" for about a month before anyone noticed that a clean result and
an unasked question produce identical output.

The two controls are the `axiomAnchor : True` idiom, which concludes `True` on purpose in order to
pin a footprint, and an ordinary file with real content. Anything that flags those is unusable in
practice, which is the whole reason they are in there.

Everything is MIT and runnable: <https://github.com/xaviercallens/SocrateAI-Scientific-Elenchus>.
There is a small checker and a regression runner, so you can point a judge at it and get a table
rather than a pile of files. If it is more useful, I am happy to run check (b) against the corpus
myself and report what it catches and misses.

One thing I should state plainly, because the repositories these came from are Navier–Stokes
projects: I have no result on Navier–Stokes, and none of this bears on it. Those repositories are
the setting, not the finding. The work is AI-assisted throughout and says so in its own disclosure.

---

## If someone replies

- **"This is already known."** Partly true, and say so. The folklore that the statement is the hard
  part is well established. What is not established is how often it happens in practice and whether
  an LLM judge catches it. The corpus is the empirical half, not the idea.
- **"Show the real repository."** Decline politely. The tree is proprietary and the shapes have
  been reduced to minimal fixtures precisely so the finding can be public without it.
- **"What does your checker get?"** Run it and report honestly, including the four bugs it had on
  first execution. That story is more persuasive than a clean result.
