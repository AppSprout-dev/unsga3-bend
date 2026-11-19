#!/usr/bin/env python3
"""Hand checks for E_assoc and the shuffled control. No Bend run."""

from __future__ import annotations

import math
import random
import unittest
from itertools import combinations

from best_of_k import (
    CONTROL_BAND,
    DISJOINT_TRIPLES,
    IMPROVE_MIN,
    K,
    PROBLEMS,
    RHO_MIN,
    SEEDS,
    SHUFFLE_SEED,
    WORSE_MAX,
    analyze_problem,
    e_assoc,
    position_permutation,
    spearman,
    summarize,
)


class EnergyHandTest(unittest.TestCase):
    def test_off_ray_mean_on_the_two_objective_axes(self) -> None:
        # p=1 rays are (0, 1) and (1, 0). Ideal and nadir are (0, 0) and (1, 1),
        # so the points are already normalized. Nearest distances: 0, 0.5, 0.
        front = [[0.0, 1.0], [0.5, 0.6], [1.0, 0.0]]
        got = e_assoc(front, partitions=1)
        assert got is not None
        self.assertTrue(math.isclose(float(got["E_assoc"]), 1.0 / 6.0))
        self.assertEqual(got["uncovered"], 0.0)
        self.assertEqual(got["n"], 3)

    def test_dominated_row_is_dropped_before_the_mean(self) -> None:
        # (0.5, 0.6) dominates (0.6, 0.7). The other two stay.
        # Keeping the dominated row would change both n and the mean
        # (its nearest-ray distance is 0.6, and ideal/nadir would not move).
        front = [[0.0, 1.0], [0.5, 0.6], [1.0, 0.0], [0.6, 0.7]]
        got = e_assoc(front, partitions=1)
        assert got is not None
        self.assertEqual(got["n"], 3)
        self.assertTrue(math.isclose(float(got["E_assoc"]), 1.0 / 6.0))
        self.assertEqual(got["uncovered"], 0.0)

    def test_flat_front_uses_unit_denominator(self) -> None:
        # One point: ideal equals nadir, span falls under 1e-12, denom is 1.
        # The normalized point is the origin, distance 0 to every ray,
        # and the tie keeps the first ray.
        got = e_assoc([[2.0, 5.0]], partitions=1)
        assert got is not None
        self.assertEqual(got["n"], 1)
        self.assertEqual(float(got["E_assoc"]), 0.0)
        self.assertTrue(math.isclose(float(got["uncovered"]), 0.5))

    def test_ideal_nadir_puts_a_shifted_front_on_the_rays(self) -> None:
        # Raw points are not on the p=1 rays. After the front's own
        # ideal (1, 1) and nadir (3, 3) they are (0, 1) and (1, 0).
        front = [[1.0, 3.0], [3.0, 1.0]]
        got = e_assoc(front, partitions=1)
        assert got is not None
        self.assertEqual(float(got["E_assoc"]), 0.0)
        self.assertEqual(float(got["uncovered"]), 0.0)

    def test_reference_rays_have_zero_energy(self) -> None:
        from igd_vs_pymoo import das_dennis

        for n_obj, partitions in ((2, 12), (3, 12)):
            rays = das_dennis(n_obj, partitions)
            got = e_assoc(rays, partitions=partitions)
            assert got is not None
            self.assertEqual(got["n"], len(rays))
            self.assertTrue(math.isclose(float(got["E_assoc"]), 0.0, abs_tol=1e-12))
            self.assertEqual(float(got["uncovered"]), 0.0)

    def test_three_objective_off_axis_point(self) -> None:
        # ND pair. (1, 0, 0) sits on a ray (distance 0).
        # (0, 1, 1) is distance 1 from either of the other two axes.
        front = [[1.0, 0.0, 0.0], [0.0, 1.0, 1.0]]
        got = e_assoc(front, partitions=1)
        assert got is not None
        self.assertTrue(math.isclose(float(got["E_assoc"]), 0.5))
        self.assertTrue(math.isclose(float(got["uncovered"]), 1.0 / 3.0))


class ShuffleControlTest(unittest.TestCase):
    def test_permutation_is_deterministic_and_bijective(self) -> None:
        first = position_permutation(15, SHUFFLE_SEED)
        second = position_permutation(15, SHUFFLE_SEED)
        self.assertEqual(first, second)
        self.assertEqual(sorted(first), list(range(15)))
        again = position_permutation(15, SHUFFLE_SEED)
        self.assertEqual(again, first)

    def test_analyze_shuffled_picks_do_not_move(self) -> None:
        rows = [
            {
                "problem": "zdt1",
                "seed": seed,
                "E_assoc": float(seed) / 10.0,
                "IGD": 1.0 / seed,
                "uncovered": 0.0,
                "n": 4,
            }
            for seed in range(1, 8)
        ]
        left = analyze_problem(rows)
        right = analyze_problem(rows)
        self.assertEqual(left["shuffle_perm"], right["shuffle_perm"])
        self.assertEqual(left["disjoint"], right["disjoint"])
        self.assertEqual(left["median_igd_shuffled"], right["median_igd_shuffled"])
        # The control is that permutation, not a fresh draw inside the triple.
        rng = random.Random(SHUFFLE_SEED)
        perm = list(range(len(rows)))
        for i in range(len(perm) - 1, 0, -1):
            j = rng.randrange(i + 1)
            perm[i], perm[j] = perm[j], perm[i]
        self.assertEqual(left["shuffle_perm"], perm)

    def test_registered_grid_size(self) -> None:
        self.assertEqual(len(list(combinations(SEEDS, K))), 455)
        self.assertEqual(len(PROBLEMS), 3)
        covered = [seed for triple in DISJOINT_TRIPLES for seed in triple]
        self.assertEqual(covered, list(SEEDS))

    def test_spearman_hand_values(self) -> None:
        self.assertTrue(math.isclose(spearman([1, 2, 3], [1, 2, 3]) or 0.0, 1.0))
        self.assertTrue(math.isclose(spearman([1, 2, 3], [3, 2, 1]) or 0.0, -1.0))
        # Ranks (1, 2, 3) against (1, 3, 2). Pearson of those ranks is 0.5.
        self.assertTrue(math.isclose(spearman([1, 2, 3], [1, 3, 2]) or 0.0, 0.5))
        self.assertIsNone(spearman([1, 1, 1], [1, 2, 3]))

    def test_criterion_boundaries_are_the_registered_ones(self) -> None:
        # Three copies of a monotone cloud. Energy pick equals the oracle,
        # so the median best-of-3 IGD is the median of the triple minima.
        def cloud(problem: str, scale: float) -> list[dict]:
            rows = []
            for seed in SEEDS:
                rows.append(
                    {
                        "problem": problem,
                        "seed": seed,
                        "E_assoc": scale * seed,
                        "IGD": scale * seed,
                        "uncovered": 0.0,
                        "n": 8,
                    }
                )
            return rows

        rows = []
        for problem in PROBLEMS:
            rows.extend(cloud(problem, 1.0))
        summary = summarize(rows)
        self.assertEqual(summary["protocol"]["shuffle_seed"], SHUFFLE_SEED)
        self.assertEqual(summary["protocol"]["k"], K)
        self.assertEqual(summary["criterion_a"]["rho_min"], RHO_MIN)
        self.assertEqual(summary["criterion_b"]["improve_min"], IMPROVE_MIN)
        self.assertEqual(summary["criterion_b"]["worse_max"], WORSE_MAX)
        self.assertEqual(summary["criterion_c"]["band"], CONTROL_BAND)
        for problem in PROBLEMS:
            block = summary["problems"][problem]
            self.assertEqual(block["n_triples"], 455)
            self.assertTrue(block["rho_pass"])
            self.assertGreaterEqual(block["rel_energy"], IMPROVE_MIN)
            self.assertTrue(block["not_worse_pass"])
        self.assertTrue(summary["criterion_a"]["pass"])
        self.assertTrue(summary["criterion_b"]["pass"])
        # The synthetic IGD is 1..15. A single shuffle is a real control,
        # not forced inside the band. Only check that the same seed repeats.
        again = summarize(rows)
        self.assertEqual(
            summary["problems"]["zdt1"]["median_igd_shuffled"],
            again["problems"]["zdt1"]["median_igd_shuffled"],
        )


if __name__ == "__main__":
    raise SystemExit(unittest.main())
