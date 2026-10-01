"""GD / GD+ / IGD / IGD+ matching C# PerformanceIndicators.

Minimization. Modified distance is the Euclidean norm of
``max(a_j - z_j, 0)`` (Ishibuchi). GD+ averages that distance from each
obtained point to the nearest reference point. IGD+ averages it from each
reference point to the nearest obtained point.

No Bend indicator module. A/B IGD stays in ``igd_vs_pymoo.py`` (pymoo's
IGD). This helper is the GD+ hand-check and can score a front without
pymoo. It does not invent IGD / HV / Wilcoxon numbers.
"""

from __future__ import annotations

import math


def modified_distance(a: list[float], z: list[float]) -> float:
    """Euclidean norm of max(a_j - z_j, 0). ``a`` is obtained, ``z`` is reference."""
    if len(a) != len(z):
        raise ValueError("objective vectors must have the same length")
    total = 0.0
    for ai, zi in zip(a, z):
        d = ai - zi
        if d < 0.0:
            d = 0.0
        total += d * d
    return math.sqrt(total)


def _euclidean(a: list[float], b: list[float]) -> float:
    if len(a) != len(b):
        raise ValueError("objective vectors must have the same length")
    return math.sqrt(sum((ai - bi) * (ai - bi) for ai, bi in zip(a, b)))


def _mean_min(rows: list[list[float]], cols: list[list[float]], dist) -> float:
    if not rows or not cols:
        return math.inf
    total = 0.0
    for row in rows:
        best = math.inf
        for col in cols:
            d = dist(row, col)
            if d < best:
                best = d
        total += best
    return total / len(rows)


def generational_distance(obtained: list[list[float]], reference: list[list[float]]) -> float:
    """Mean Euclidean distance from each obtained point to the nearest reference point."""
    return _mean_min(obtained, reference, _euclidean)


def generational_distance_plus(obtained: list[list[float]], reference: list[list[float]]) -> float:
    """GD+: mean over obtained of min modified distance to a reference point."""
    return _mean_min(obtained, reference, modified_distance)


def inverted_generational_distance(obtained: list[list[float]], reference: list[list[float]]) -> float:
    """IGD: mean Euclidean distance from each reference point to the nearest obtained point."""
    return _mean_min(reference, obtained, _euclidean)


def inverted_generational_distance_plus(
    obtained: list[list[float]], reference: list[list[float]]
) -> float:
    """IGD+: mean over reference of min ModifiedDistance(obtained, reference)."""
    if not obtained or not reference:
        return math.inf
    total = 0.0
    for z in reference:
        best = math.inf
        for a in obtained:
            d = modified_distance(a, z)
            if d < best:
                best = d
        total += best
    return total / len(reference)
