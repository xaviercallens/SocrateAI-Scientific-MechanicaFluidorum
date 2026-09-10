import Lake
open Lake DSL

package mechanicaFluidorum

/-- Mathlib is PINNED to the exact revision the program's Gate-2 environment has been
compiling against (`~/xdev/SocrateAI-Scientific-RajMathRecovery/dualscale/lean`, whose
`lake-manifest.json` records this rev alongside toolchain `leanprover/lean4:v4.33.0-rc2`,
matching `lean-toolchain` here).

Do NOT replace this with an unpinned `require mathlib from git "..."`: that resolves to
Mathlib master, which in general does not build against a pinned older toolchain, and would
make a "cold build" silently test a different Mathlib than every result in `LEDGER.md` was
verified against. -/
require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @ "6d605ae1ac45de240cdb83ce104fe60b3c1d9237"

@[default_target]
lean_lib LocalDualScale

@[default_target]
lean_lib DyadicShells

@[default_target]
lean_lib DyadicShell_Statements

@[default_target]
lean_lib EnstrophyProduction

@[default_target]
lean_lib EnstrophyProductionBound

@[default_target]
lean_lib MillenniumReduction

@[default_target]
lean_lib AbstractAlgebraicConservation

/- `TriadTorus` and `DyadicRiccati` are deliberately NOT targets. Nothing imports them, and
Gate 2 re-elaborates them file-by-file with `lean`, which is how they have always been checked.
Making them default targets forces `lake build` to compile their heavy Mathlib dependencies
(measure theory, `ZMod`), which exhausted this machine's memory — the kernel check gains
nothing from it. Add a target only when another file must `import` the module. -/

/-- OP-6a kinematics. A `lean_lib` target (not merely a file Gate 2 re-elaborates) because
`FourierDynamicsZ3` imports it: without a target there is no `.olean` to import, and the
cross-file import fails with "object file does not exist". -/
@[default_target]
lean_lib FourierStateZ3

/-- OP-6b, first slice: the Leray-projected bilinear operator `B` and the energy-conservation
statement. Imports `FourierStateZ3`. -/
@[default_target]
lean_lib FourierDynamicsZ3
