"""Shared A/B / oracle Run defaults for dump helpers.

ZDT2 A/B default in this tree is **gens=250**, still PymooCompatible,
p=12, pop=52. gens=100 is an early-stress snapshot (Bend 10/15 and C# 8/15
collapse on PR #16); the 15-seed gens=250 table is 0/15 on both stacks —
see docs/ZDT2_COLLAPSE.md. ZDT1 stays 100; DTLZ2 stays 150.

RankNicheDistance (`--tournament rank_niche`) is an optional lever, not
the A/B default.

Explicit `--gens` / `--pop` / `--partitions` on a dumper always win.
"""

from __future__ import annotations

ORACLE_PARTITIONS = 12
ORACLE_POP_ZDT = 52
ORACLE_POP_DTLZ2 = 92
ORACLE_GENS_ZDT1 = 100
ORACLE_GENS_ZDT2 = 250
ORACLE_GENS_DTLZ2 = 150
ORACLE_SEED = 1
# A/B / smoke default. C# ctor default RankNicheDistance is --tournament rank_niche.
ORACLE_TOURNAMENT = "pymoo"


def default_gens(problem: str, *, dtlz2_gens: int | None = None) -> int:
    """Default generations when a dumper omits --gens.

    `dtlz2_gens` keeps dump_bend_run / profile_bend_run at their historical
    implicit 100 for DTLZ2 (callers that meant the oracle pass --gens 150).
    dump_csharp_run uses ORACLE_GENS_DTLZ2 (150).
    """
    if problem == "zdt2":
        return ORACLE_GENS_ZDT2
    if problem == "dtlz2":
        return ORACLE_GENS_DTLZ2 if dtlz2_gens is None else dtlz2_gens
    return ORACLE_GENS_ZDT1


def default_pop(problem: str) -> int:
    return ORACLE_POP_DTLZ2 if problem == "dtlz2" else ORACLE_POP_ZDT
