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
lean_lib CallensDualScale

@[default_target]
lean_lib DyadicShells

@[default_target]
lean_lib HypothesisU_Statements

@[default_target]
lean_lib EnstrophyProduction

@[default_target]
lean_lib EnstrophyProductionBound

@[default_target]
lean_lib MillenniumReduction

@[default_target]
lean_lib TriadConservation
