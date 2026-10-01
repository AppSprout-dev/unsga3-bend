#!/usr/bin/env python3
"""GD+ hand cases. No Bend run. No measured IGD."""

from __future__ import annotations

import math
import unittest

from indicators import (
    generational_distance,
    generational_distance_plus,
    inverted_generational_distance_plus,
    modified_distance,
)


class GdPlusTest(unittest.TestCase):
    def test_modified_distance_clips_improvement(self) -> None:
        self.assertEqual(modified_distance([0.0, 0.0], [1.0, 0.0]), 0.0)
        self.assertEqual(modified_distance([0.0, 1.0], [0.0, 0.0]), 1.0)

    def test_shared_hand_case_is_one(self) -> None:
        obtained = [[0.0, 1.0]]
        reference = [[0.0, 0.0], [1.0, 0.0]]
        self.assertEqual(generational_distance(obtained, reference), 1.0)
        self.assertEqual(generational_distance_plus(obtained, reference), 1.0)
        self.assertEqual(inverted_generational_distance_plus(obtained, reference), 1.0)

    def test_weakly_better_point_is_gd_plus_zero(self) -> None:
        obtained = [[0.0, 0.0]]
        reference = [[1.0, 0.0]]
        self.assertEqual(generational_distance(obtained, reference), 1.0)
        self.assertEqual(generational_distance_plus(obtained, reference), 0.0)

    def test_empty_is_infinite(self) -> None:
        self.assertTrue(math.isinf(generational_distance_plus([], [[0.0]])))
        self.assertTrue(math.isinf(generational_distance_plus([[0.0]], [])))


if __name__ == "__main__":
    raise SystemExit(unittest.main())
