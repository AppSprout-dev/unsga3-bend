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

    Omit `dtlz2_gens` for the oracle (DTLZ2 = 150). `dump_bend_run` and
    `profile_bend_run` do that. Pass `dtlz2_gens=100` only to rebuild the
    old generated-driver budget on purpose.
    """
    if problem == "zdt2":
        return ORACLE_GENS_ZDT2
    if problem == "dtlz2":
        return ORACLE_GENS_DTLZ2 if dtlz2_gens is None else dtlz2_gens
    return ORACLE_GENS_ZDT1


def default_pop(problem: str) -> int:
    return ORACLE_POP_DTLZ2 if problem == "dtlz2" else ORACLE_POP_ZDT


def fill_omitted(
    problem: str | None,
    *,
    partitions: int | None = None,
    pop: int | None = None,
    gens: int | None = None,
    seed: int | None = None,
    tournament: str | None = None,
) -> dict[str, int | str]:
    """Fill a generated Run driver when flags are omitted.

    Explicit values always win. DTLZ2 omissions are the oracle
    (pop 92, gens 150), same as `oracle_knobs`. ZDT1 stays 100/52.
    ZDT2 stays 250/52. Tournament stays PymooCompatible.
    """
    name = problem or "zdt1"
    return {
        "problem": name,
        "partitions": ORACLE_PARTITIONS if partitions is None else partitions,
        "pop": default_pop(name) if pop is None else pop,
        "gens": default_gens(name) if gens is None else gens,
        "seed": ORACLE_SEED if seed is None else seed,
        "tournament": tournament or ORACLE_TOURNAMENT,
    }


def n_var(problem: str) -> int:
    """Decision-variable count for the published ZDT / DTLZ2 oracles."""
    if problem == "dtlz2":
        return 12  # M=3, k=10
    return 30


def n_obj(problem: str) -> int:
    return 3 if problem == "dtlz2" else 2


def oracle_knobs(problem: str) -> dict[str, int | str]:
    """Explicit A/B knobs (always pass these to dumpers; no omitted-flag traps)."""
    return {
        "problem": problem,
        "partitions": ORACLE_PARTITIONS,
        "pop": default_pop(problem),
        "gens": default_gens(problem),
        "tournament": ORACLE_TOURNAMENT,
        "n_var": n_var(problem),
        "n_obj": n_obj(problem),
    }
