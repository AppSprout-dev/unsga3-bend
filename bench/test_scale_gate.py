#!/usr/bin/env python3
"""Decision checks for the scaling gate. No Bend binary and no timings."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import scale_gate as gate


def _cell(pop: int, refs: int, algo: float, wall: float, rss: float) -> dict[str, float]:
    return {
        "pop": float(pop),
        "ref_points": float(refs),
        "algo_ms": algo,
        "wall_s": wall,
        "rss_kb": rss,
    }


def _samples_from_baseline(baseline: dict) -> dict[str, dict[str, float]]:
    return gate.view(baseline["cells"])


class ExponentTests(unittest.TestCase):
    def test_quadratic(self) -> None:
        slope = gate.log_log_exponent([1, 2, 4, 8], [3, 12, 48, 192])
        self.assertAlmostEqual(slope, 2.0, places=9)

    def test_linear(self) -> None:
        slope = gate.log_log_exponent([10, 20, 40], [5, 10, 20])
        self.assertAlmostEqual(slope, 1.0, places=9)

    def test_scale_invariance(self) -> None:
        xs = [23, 46, 92]
        ys = [37, 84, 225]
        slowed = [y * 3.5 for y in ys]
        self.assertAlmostEqual(
            gate.log_log_exponent(xs, ys),
            gate.log_log_exponent(xs, slowed),
            places=9,
        )


class DecisionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.baseline = {
            "bounds": dict(gate.LOCKED_BOUNDS),
            "cells": {},
        }
        # Shape close to a sub-quadratic N series and a flat R / RSS series.
        rows = {
            "m0idle": (0, 0, 1.0, 0.001, 11000),
            "m3p12n23": (23, 91, 40.0, 0.040, 11800),
            "m3p12n46": (46, 91, 90.0, 0.090, 11800),
            "m3p12n92": (92, 91, 240.0, 0.240, 11800),
            "m3p4n92": (92, 15, 200.0, 0.200, 11800),
            "m3p8n92": (92, 45, 220.0, 0.220, 11800),
            "m5p4n70": (70, 70, 180.0, 0.180, 11800),
            "m8p2n36": (36, 36, 80.0, 0.080, 11800),
            "m8p3n120": (120, 120, 500.0, 0.500, 12000),
        }
        for name, (pop, refs, algo, wall, rss) in rows.items():
            self.baseline["cells"][name] = {
                "pop": pop,
                "ref_points": refs,
                "algo_ms": {"median": algo},
                "wall_s": {"median": wall},
                "rss_kb": {"median": rss},
            }
        self.samples = _samples_from_baseline(self.baseline)

    def test_identical_run_passes(self) -> None:
        self.assertEqual(gate.evaluate(self.samples, self.baseline), [])

    def test_uniform_slowdown_passes(self) -> None:
        slowed = {
            name: dict(row, algo_ms=row["algo_ms"] * 4, wall_s=row["wall_s"] * 4)
            for name, row in self.samples.items()
        }
        self.assertEqual(gate.evaluate(slowed, self.baseline), [])

    def test_cubic_n_series_fails_ceiling(self) -> None:
        # N^3 on the N series, leaving every other cell on the baseline.
        cubic = {name: dict(row) for name, row in self.samples.items()}
        for name, pop in (("m3p12n23", 23), ("m3p12n46", 46), ("m3p12n92", 92)):
            cubic[name]["algo_ms"] = float(pop ** 3) / 100.0
            cubic[name]["wall_s"] = cubic[name]["algo_ms"] / 1000.0
        failures = gate.evaluate(cubic, self.baseline)
        self.assertTrue(any("time_vs_n exponent" in item and "ceiling" in item for item in failures))
        self.assertTrue(any("wall_vs_n exponent" in item and "ceiling" in item for item in failures))

    def test_anchor_only_regression_fails_endpoint_ratio(self) -> None:
        bumped = {name: dict(row) for name, row in self.samples.items()}
        bumped["m3p12n92"]["algo_ms"] *= 8
        bumped["m3p12n92"]["wall_s"] *= 8
        failures = gate.evaluate(bumped, self.baseline)
        self.assertTrue(any(item.startswith("time_vs_n endpoint ratio") for item in failures))

    def test_memory_lift_at_large_n_fails_rss_ratio(self) -> None:
        bumped = {name: dict(row) for name, row in self.samples.items()}
        bumped["m3p12n92"]["rss_kb"] *= 2
        failures = gate.evaluate(bumped, self.baseline)
        self.assertTrue(any("rss_vs_n endpoint ratio" in item for item in failures))


class BaselineFileTests(unittest.TestCase):
    def test_committed_bounds_match_the_lock(self) -> None:
        path = Path(__file__).resolve().parent / "baseline.json"
        payload = json.loads(path.read_text())
        self.assertEqual(payload["bounds"], gate.LOCKED_BOUNDS)
        self.assertEqual(payload["gens"], gate.GENS)
        self.assertEqual(payload["threads"], gate.THREADS)
        self.assertEqual(payload["anchor"], gate.ANCHOR)
        for name, (m, partitions, pop) in gate.CELLS.items():
            blob = payload["cells"][name]
            self.assertEqual((blob["m"], blob["partitions"], blob["pop"]), (m, partitions, pop))
            for key in ("algo_ms", "wall_s", "rss_kb", "run_ms", "burn_ms"):
                repeats = blob[key]["repeats"]
                self.assertEqual(len(repeats), payload["repeats"])
                self.assertAlmostEqual(blob[key]["median"], gate.median(repeats), places=6)
        samples = gate.view(payload["cells"])
        self.assertEqual(gate.evaluate(samples, payload), [])
        for spec in gate.SERIES:
            current = gate.series_exponent(samples, spec)
            ceiling = payload["bounds"][spec["ceiling"]]
            self.assertLessEqual(current, ceiling)


if __name__ == "__main__":
    unittest.main()
