#!/usr/bin/env python3
"""Omitted generated-driver knobs match ab/protocol.py.

No Bend run. No IGD. `dump_bend_run.py` and `profile_bend_run.py` both
fill omissions through `protocol.fill_omitted`.
"""

from __future__ import annotations

import unittest

from dump_bend_run import generate_bend
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


if __name__ == "__main__":
    raise SystemExit(unittest.main())
