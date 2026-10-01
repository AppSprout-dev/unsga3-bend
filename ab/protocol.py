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


# Catalog A/B. Separate from oracle_knobs. Does not change ZDT1 / ZDT2 / DTLZ2.
#
# C# tools/OracleCompare only accepts zdt1, zdt2, dtlz2, and C# has no
# published catalog IGD table. Bi-objective catalog names use the ZDT1
# quality budget. DTLZ catalog names use the DTLZ2 quality budget.
# Dimensions are the C# constructor defaults (Zdt4 n=10, Dtlz1 k=5, …).
# Single-objective names are a short smoke: one Das–Dennis direction,
# pop=20, gens=40, library-default n. C# CI smokes use smaller n,
# RankNicheDistance, and different pop/gens; they are not this budget.
# Omitted flags on dump_bend_run stay the 4/8/3 smoke, not these knobs.

CATALOG_ZDT = ("zdt3", "zdt4", "zdt6")
CATALOG_DTLZ = ("dtlz1", "dtlz3", "dtlz4", "dtlz7")
CATALOG_SO = ("sphere", "ackley", "rosenbrock")
CATALOG_PROBLEMS = CATALOG_ZDT + CATALOG_DTLZ + CATALOG_SO

# OSY / TNK / C1-DTLZ1 are implemented. They are not catalog_knobs rows.
# The 2026-09-30 ORACLE-CATALOG table still records them as skips.
# New measurements use constrained_knobs (PymooCompatible). C# NEW-SURFACES
# used RankNicheDistance; this budget does not flip the A/B default.
CONSTRAINED_PROBLEMS = ("osy", "tnk", "c1dtlz1")
CONSTRAINED_ABSENT = CONSTRAINED_PROBLEMS

CATALOG_SO_PARTITIONS = 1
CATALOG_SO_POP = 20
CATALOG_SO_GENS = 40


def catalog_n_var(problem: str) -> int:
    return {
        "zdt3": 30,
        "zdt4": 10,
        "zdt6": 10,
        "dtlz1": 7,  # M=3, k=5
        "dtlz3": 12,  # M=3, k=10
        "dtlz4": 12,
        "dtlz7": 22,  # M=3, k=20
        "sphere": 10,
        "ackley": 30,
        "rosenbrock": 10,
    }[problem]


def catalog_n_obj(problem: str) -> int:
    if problem in CATALOG_ZDT:
        return 2
    if problem in CATALOG_DTLZ:
        return 3
    if problem in CATALOG_SO:
        return 1
    raise KeyError(problem)


def catalog_bounds(problem: str) -> tuple[list[float], list[float]]:
    """Bend / C# box. pymoo must match this or the catalog dumper skips."""
    n = catalog_n_var(problem)
    if problem == "zdt4":
        return [0.0] + [-5.0] * (n - 1), [1.0] + [5.0] * (n - 1)
    if problem == "sphere":
        return [-5.12] * n, [5.12] * n
    if problem == "ackley":
        return [-32.768] * n, [32.768] * n
    if problem == "rosenbrock":
        return [-2.048] * n, [2.048] * n
    return [0.0] * n, [1.0] * n


def constrained_knobs(problem: str) -> dict[str, int | str]:
    """OSY / TNK / C1-DTLZ1 sizes. Not catalog_knobs. Not oracle_knobs.

    Partitions, pop, and gens match the C# NEW-SURFACES budgets.
    Tournament stays PymooCompatible. C# scored those surfaces with
    RankNicheDistance; pass that mode explicitly if you want it.
    """
    table = {
        "osy": (12, 52, 250, 6, 2),
        "tnk": (12, 52, 250, 2, 2),
        "c1dtlz1": (12, 92, 150, 7, 3),
    }
    partitions, pop, gens, nv, nm = table[problem]
    return {
        "problem": problem,
        "partitions": partitions,
        "pop": pop,
        "gens": gens,
        "tournament": ORACLE_TOURNAMENT,
        "n_var": nv,
        "n_obj": nm,
    }


def constrained_bounds(problem: str) -> tuple[list[float], list[float]]:
    """Bend / C# box for the three constrained demos."""
    if problem == "osy":
        return [0.0, 0.0, 1.0, 0.0, 1.0, 0.0], [10.0, 10.0, 5.0, 6.0, 5.0, 10.0]
    if problem == "tnk":
        # Bend F32.pi() prints 3.1415927. The lower y bound is 1e-30.
        pi = 3.1415927
        return [0.0, 1.0e-30], [pi, pi]
    if problem == "c1dtlz1":
        return [0.0] * 7, [1.0] * 7
    raise KeyError(problem)


def catalog_knobs(problem: str) -> dict[str, int | str]:
    """Explicit catalog knobs. Not oracle_knobs. Not the 4/8/3 dump smoke."""
    if problem in CATALOG_ZDT:
        partitions, pop, gens = ORACLE_PARTITIONS, ORACLE_POP_ZDT, ORACLE_GENS_ZDT1
        sibling = "zdt1"
    elif problem in CATALOG_DTLZ:
        partitions, pop, gens = ORACLE_PARTITIONS, ORACLE_POP_DTLZ2, ORACLE_GENS_DTLZ2
        sibling = "dtlz2"
    elif problem in CATALOG_SO:
        partitions, pop, gens = CATALOG_SO_PARTITIONS, CATALOG_SO_POP, CATALOG_SO_GENS
        sibling = "short-smoke"
    else:
        raise KeyError(problem)
    return {
        "problem": problem,
        "partitions": partitions,
        "pop": pop,
        "gens": gens,
        "tournament": ORACLE_TOURNAMENT,
        "n_var": catalog_n_var(problem),
        "n_obj": catalog_n_obj(problem),
        "sibling": sibling,
    }
