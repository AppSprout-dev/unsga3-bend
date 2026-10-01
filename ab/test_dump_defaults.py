#!/usr/bin/env python3
"""Omitted generated-driver knobs match ab/protocol.py.

No Bend run. No IGD. `dump_bend_run.py` and `profile_bend_run.py` both
fill omissions through `protocol.fill_omitted`.
"""

from __future__ import annotations

import unittest

from dump_bend_run import (
    CATALOG_SMOKE_GENS,
    CATALOG_SMOKE_PARTITIONS,
    CATALOG_SMOKE_POP,
    generate_bend,
    resolve_dump_knobs,
)
from protocol import ORACLE_GENS_DTLZ2, ORACLE_POP_DTLZ2, fill_omitted


class FillOmittedTest(unittest.TestCase):
    def test_dtlz2_omitted_matches_oracle(self) -> None:
        knobs = fill_omitted("dtlz2")
        self.assertEqual(knobs["pop"], ORACLE_POP_DTLZ2)
        self.assertEqual(knobs["gens"], ORACLE_GENS_DTLZ2)
        self.assertEqual(knobs["pop"], 92)
        self.assertEqual(knobs["gens"], 150)
        src = generate_bend("dtlz2", 12, int(knobs["pop"]), int(knobs["gens"]), 1)
        self.assertIn("92n", src)
        self.assertIn("150n", src)
        self.assertNotIn("52n", src)
        self.assertNotIn("100n", src)

    def test_explicit_dtlz2_flags_win(self) -> None:
        knobs = fill_omitted("dtlz2", pop=52, gens=100)
        self.assertEqual(knobs["pop"], 52)
        self.assertEqual(knobs["gens"], 100)

    def test_zdt_omissions_unchanged(self) -> None:
        zdt1 = fill_omitted("zdt1")
        zdt2 = fill_omitted("zdt2")
        self.assertEqual((zdt1["pop"], zdt1["gens"]), (52, 100))
        self.assertEqual((zdt2["pop"], zdt2["gens"]), (52, 250))
        self.assertEqual(fill_omitted(None)["problem"], "zdt1")

    def test_catalog_omitted_is_smoke_not_zdt1_oracle(self) -> None:
        knobs = resolve_dump_knobs("zdt3")
        self.assertEqual(knobs["partitions"], CATALOG_SMOKE_PARTITIONS)
        self.assertEqual(knobs["pop"], CATALOG_SMOKE_POP)
        self.assertEqual(knobs["gens"], CATALOG_SMOKE_GENS)
        self.assertEqual((knobs["pop"], knobs["gens"], knobs["partitions"]), (8, 3, 4))
        src = generate_bend("zdt3", 4, 8, 3, 1)
        self.assertIn("Prob.zdt3(30n)", src)
        self.assertIn("das_dennis(2n, 4n), 8n, 3n, 1n", src)
        self.assertNotIn("52n", src)
        self.assertNotIn("100n", src)
        explicit = resolve_dump_knobs("sphere", partitions=12, pop=52, gens=100)
        self.assertEqual((explicit["pop"], explicit["gens"], explicit["partitions"]), (52, 100, 12))
        self.assertIn("Prob.sphere(10n)", generate_bend("sphere", 12, 52, 100, 1))
        osy = resolve_dump_knobs("osy")
        self.assertEqual((osy["pop"], osy["gens"], osy["partitions"]), (8, 3, 4))
        osy_src = generate_bend("osy", 12, 52, 250, 1)
        self.assertIn("Prob.osy()", osy_src)
        self.assertIn("Algo.feas_nd", osy_src)
        self.assertNotIn("Algo.nd_front", osy_src)
        self.assertIn("Algo.nd_front", generate_bend("zdt1", 12, 52, 100, 1))
        # Quality budgets stay on the three oracle names.
        zdt1 = resolve_dump_knobs("zdt1")
        dtlz2 = resolve_dump_knobs("dtlz2")
        self.assertEqual((zdt1["pop"], zdt1["gens"]), (52, 100))
        self.assertEqual((dtlz2["pop"], dtlz2["gens"]), (92, 150))


if __name__ == "__main__":
    raise SystemExit(unittest.main())
