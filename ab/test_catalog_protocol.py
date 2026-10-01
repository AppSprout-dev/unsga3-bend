#!/usr/bin/env python3
"""Catalog knobs and Pareto-front geometry. No Bend run. No IGD numbers."""

from __future__ import annotations

import math
import unittest

from dump_bend_run import resolve_dump_knobs
from igd_vs_pymoo import (
    ZDT3_INTERVALS,
    ZDT3_POINTS_PER_SEGMENT,
    ZDT6_F1_MIN,
    dtlz1_pf,
    zdt1_pf,
    zdt3_f2,
    zdt3_pf,
    zdt6_pf,
)
from protocol import (
    catalog_bounds,
    catalog_knobs,
    constrained_knobs,
    oracle_knobs,
)


class OracleUntouchedTest(unittest.TestCase):
    def test_quality_budgets_stay(self) -> None:
        zdt1 = oracle_knobs("zdt1")
        zdt2 = oracle_knobs("zdt2")
        dtlz2 = oracle_knobs("dtlz2")
        self.assertEqual((zdt1["pop"], zdt1["gens"], zdt1["partitions"]), (52, 100, 12))
        self.assertEqual((zdt2["pop"], zdt2["gens"], zdt2["partitions"]), (52, 250, 12))
        self.assertEqual((dtlz2["pop"], dtlz2["gens"], dtlz2["n_var"]), (92, 150, 12))
        self.assertEqual(zdt1["tournament"], "pymoo")

    def test_catalog_omissions_stay_smoke(self) -> None:
        knobs = resolve_dump_knobs("zdt3")
        self.assertEqual((knobs["partitions"], knobs["pop"], knobs["gens"]), (4, 8, 3))
        explicit = resolve_dump_knobs("dtlz1", partitions=12, pop=92, gens=150)
        self.assertEqual((explicit["partitions"], explicit["pop"], explicit["gens"]), (12, 92, 150))


class CatalogKnobsTest(unittest.TestCase):
    def test_sibling_budgets(self) -> None:
        for name in ("zdt3", "zdt4", "zdt6"):
            knobs = catalog_knobs(name)
            self.assertEqual(knobs["sibling"], "zdt1")
            self.assertEqual((knobs["partitions"], knobs["pop"], knobs["gens"]), (12, 52, 100))
            self.assertEqual(knobs["tournament"], "pymoo")
            self.assertEqual(knobs["n_obj"], 2)
        self.assertEqual(catalog_knobs("zdt3")["n_var"], 30)
        self.assertEqual(catalog_knobs("zdt4")["n_var"], 10)
        self.assertEqual(catalog_knobs("zdt6")["n_var"], 10)
        for name, n_var in (("dtlz1", 7), ("dtlz3", 12), ("dtlz4", 12), ("dtlz7", 22)):
            knobs = catalog_knobs(name)
            self.assertEqual(knobs["sibling"], "dtlz2")
            self.assertEqual((knobs["partitions"], knobs["pop"], knobs["gens"], knobs["n_var"]), (12, 92, 150, n_var))
            self.assertEqual(knobs["n_obj"], 3)
        for name, n_var in (("sphere", 10), ("ackley", 30), ("rosenbrock", 10)):
            knobs = catalog_knobs(name)
            self.assertEqual(knobs["sibling"], "short-smoke")
            self.assertEqual((knobs["partitions"], knobs["pop"], knobs["gens"], knobs["n_var"], knobs["n_obj"]), (1, 20, 40, n_var, 1))

    def test_boxes(self) -> None:
        xl, xu = catalog_bounds("zdt4")
        self.assertEqual(xl[0], 0.0)
        self.assertEqual(xu[0], 1.0)
        self.assertEqual(xl[-1], -5.0)
        self.assertEqual(xu[-1], 5.0)
        self.assertEqual(catalog_bounds("sphere")[0][0], -5.12)
        self.assertEqual(catalog_bounds("ackley")[1][0], 32.768)
        self.assertEqual(catalog_bounds("dtlz7")[0], [0.0] * 22)


class ConstrainedKnobsTest(unittest.TestCase):
    def test_budgets_stay_pymoo(self) -> None:
        osy = constrained_knobs("osy")
        tnk = constrained_knobs("tnk")
        c1 = constrained_knobs("c1dtlz1")
        self.assertEqual((osy["partitions"], osy["pop"], osy["gens"], osy["n_var"], osy["n_obj"]), (12, 52, 250, 6, 2))
        self.assertEqual((tnk["partitions"], tnk["pop"], tnk["gens"], tnk["n_var"], tnk["n_obj"]), (12, 52, 250, 2, 2))
        self.assertEqual((c1["partitions"], c1["pop"], c1["gens"], c1["n_var"], c1["n_obj"]), (12, 92, 150, 7, 3))
        self.assertEqual(osy["tournament"], "pymoo")
        self.assertEqual(tnk["tournament"], "pymoo")
        self.assertEqual(c1["tournament"], "pymoo")
        # Omitted dump flags stay the short smoke, not this budget.
        smoke = resolve_dump_knobs("osy")
        self.assertEqual((smoke["partitions"], smoke["pop"], smoke["gens"]), (4, 8, 3))
        self.assertEqual(oracle_knobs("zdt1")["tournament"], "pymoo")


class ParetoGeometryTest(unittest.TestCase):
    def test_zdt3_matches_csharp_segments(self) -> None:
        pf = zdt3_pf()
        self.assertEqual(len(ZDT3_INTERVALS), 5)
        self.assertEqual(ZDT3_POINTS_PER_SEGMENT, 100)
        self.assertEqual(len(pf), 500)
        self.assertEqual(pf[0][0], 0.0)
        self.assertAlmostEqual(pf[0][1], 1.0)
        self.assertAlmostEqual(zdt3_f2(0.0), 1.0)
        # Second segment starts at the C# literal, not pymoo's 0.182228780.
        self.assertEqual(ZDT3_INTERVALS[1][0], 0.1822287280)
        self.assertAlmostEqual(pf[100][0], 0.1822287280)

    def test_zdt6_floor(self) -> None:
        pf = zdt6_pf(500)
        self.assertEqual(len(pf), 500)
        self.assertEqual(pf[0][0], ZDT6_F1_MIN)
        self.assertAlmostEqual(pf[0][1], 1.0 - ZDT6_F1_MIN**2)
        self.assertAlmostEqual(pf[-1][0], 1.0)
        self.assertAlmostEqual(pf[-1][1], 0.0)

    def test_dtlz1_half_simplex(self) -> None:
        pf = dtlz1_pf(3, 12)
        self.assertEqual(len(pf), 91)
        for row in pf:
            self.assertAlmostEqual(sum(row), 0.5, places=9)
            self.assertTrue(all(v >= -1e-12 for v in row))
        self.assertIn([0.5, 0.0, 0.0], [[round(v, 12) for v in row] for row in pf])

    def test_zdt4_geometry_is_zdt1(self) -> None:
        a = zdt1_pf(500)
        self.assertEqual(len(a), 500)
        self.assertAlmostEqual(a[0][1], 1.0)
        self.assertTrue(math.isclose(a[-1][0], 1.0))


if __name__ == "__main__":
    raise SystemExit(unittest.main())
