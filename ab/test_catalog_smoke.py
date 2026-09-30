#!/usr/bin/env python3
"""Catalog evaluate + short Run smoke.

Runs `bend src/catalog_smoke.bend`. Checks default dimensions, box ends,
and Evaluate(x=0.5) against the C# formulas in float32 (Bend's F32.pi
literal). A short Run must return pop=4. No IGD / HV / Wilcoxon.
"""

from __future__ import annotations

import math
import shutil
import subprocess
import sys
import unittest
from pathlib import Path

try:
    import numpy as np
except ImportError:  # pragma: no cover - numeric mirror needs numpy
    np = None  # type: ignore[assignment]

ROOT = Path(__file__).resolve().parent.parent
DRIVER = ROOT / "src" / "catalog_smoke.bend"
F32 = np.float32
PI = F32(3.14159265)  # Bend F32.pi()

# name -> (n_var, n_obj, lo0, hi0, lo_last, hi_last)
DIMS = {
    "zdt3": (30, 2, 0.0, 1.0, 0.0, 1.0),
    "zdt4": (10, 2, 0.0, 1.0, -5.0, 5.0),
    "zdt6": (10, 2, 0.0, 1.0, 0.0, 1.0),
    "dtlz1": (7, 3, 0.0, 1.0, 0.0, 1.0),
    "dtlz3": (12, 3, 0.0, 1.0, 0.0, 1.0),
    "dtlz4": (12, 3, 0.0, 1.0, 0.0, 1.0),
    "dtlz7": (22, 3, 0.0, 1.0, 0.0, 1.0),
    "sphere": (10, 1, -5.12, 5.12, -5.12, 5.12),
    "ackley": (30, 1, -32.768, 32.768, -32.768, 32.768),
    "rosenbrock": (10, 1, -2.048, 2.048, -2.048, 2.048),
}


def f32(x: float) -> np.float32:
    return F32(x)


def ones(n: int, v: float = 0.5) -> np.ndarray:
    return np.full(n, f32(v), dtype=F32)


def zdt_g(x: np.ndarray) -> np.float32:
    n = x.shape[0]
    den = f32(1.0 if n <= 1 else n - 1)
    return f32(f32(1.0) + f32(9.0) * f32(np.sum(x[1:], dtype=F32)) / den)


def dtlz1_g(x: np.ndarray, m: int) -> np.float32:
    tail = x[m - 1 :]
    s = f32(0.0)
    for xi in tail:
        d = f32(xi - f32(0.5))
        s = f32(s + f32(d * d) - f32(np.cos(f32(f32(20.0) * PI) * d)))
    return f32(f32(100.0) * f32(f32(len(tail)) + s))


def dtlz2_g(x: np.ndarray, m: int) -> np.float32:
    tail = x[m - 1 :]
    s = f32(0.0)
    for xi in tail:
        d = f32(xi - f32(0.5))
        s = f32(s + f32(d * d))
    return s


def dtlz2_map(x: np.ndarray, m: int, g: np.float32) -> list[float]:
    half = f32(PI / f32(2.0))
    out: list[float] = []
    for i in range(m):
        val = f32(f32(1.0) + g)
        for j in range(m - i - 1):
            val = f32(val * f32(np.cos(f32(x[j] * half))))
        if i > 0:
            val = f32(val * f32(np.sin(f32(x[m - i - 1] * half))))
        out.append(float(val))
    return out


def dtlz1_map(x: np.ndarray, m: int, g: np.float32) -> list[float]:
    out: list[float] = []
    for i in range(m):
        val = f32(f32(0.5) * f32(f32(1.0) + g))
        for j in range(m - i - 1):
            val = f32(val * x[j])
        if i > 0:
            val = f32(val * f32(f32(1.0) - x[m - i - 1]))
        out.append(float(val))
    return out


def reference(name: str) -> list[float]:
    n, m, *_ = DIMS[name]
    x = ones(n)
    if name == "zdt3":
        g = zdt_g(x)
        r = f32(x[0] / g)
        f1 = f32(g * f32(f32(f32(1.0) - f32(np.sqrt(r))) - f32(r * f32(np.sin(f32(f32(10.0) * PI) * x[0])))))
        return [float(x[0]), float(f1)]
    if name == "zdt4":
        g = f32(f32(1.0) + f32(10.0) * f32(n - 1))
        for xi in x[1:]:
            g = f32(g + f32(xi * xi) - f32(f32(10.0) * f32(np.cos(f32(f32(4.0) * PI) * xi))))
        return [float(x[0]), float(f32(g * f32(f32(1.0) - f32(np.sqrt(f32(x[0] / g))))))]
    if name == "zdt6":
        wave = f32(np.sin(f32(f32(6.0) * PI) * x[0])) ** f32(6.0)
        f0 = f32(f32(1.0) - f32(np.exp(f32(f32(-4.0) * x[0]))) * wave)
        den = f32(n - 1)
        mean = f32(f32(np.sum(x[1:], dtype=F32)) / den)
        g = f32(f32(1.0) + f32(9.0) * f32(mean ** f32(0.25)))
        r = f32(f0 / g)
        return [float(f0), float(f32(g * f32(f32(1.0) - f32(r * r))))]
    if name == "dtlz1":
        return dtlz1_map(x, m, dtlz1_g(x, m))
    if name == "dtlz3":
        return dtlz2_map(x, m, dtlz1_g(x, m))
    if name == "dtlz4":
        y = x.copy()
        y[: m - 1] = np.array([f32(v ** f32(100.0)) for v in y[: m - 1]], dtype=F32)
        return dtlz2_map(y, m, dtlz2_g(y, m))
    if name == "dtlz7":
        gsum = f32(np.sum(x[m - 1 :], dtype=F32))
        den = f32(len(x) - m + 1)
        g = f32(f32(1.0) + f32(9.0) * f32(gsum / den))
        g1 = f32(f32(1.0) + g)
        h = f32(m)
        fs = [float(x[i]) for i in range(m - 1)]
        for fi in fs:
            h = f32(h - f32(f32(f32(fi) / g1) * f32(f32(1.0) + f32(np.sin(f32(f32(3.0) * PI) * f32(fi))))))
        return fs + [float(f32(g1 * h))]
    if name == "sphere":
        return [float(f32(np.sum(x * x, dtype=F32)))]
    if name == "ackley":
        s1 = f32(np.sum(x * x, dtype=F32))
        s2 = f32(0.0)
        for xi in x:
            s2 = f32(s2 + f32(np.cos(f32(f32(2.0) * PI) * xi)))
        den = f32(n)
        val = f32(
            f32(f32(-20.0) * f32(np.exp(f32(f32(-0.2) * f32(np.sqrt(f32(s1 / den)))))))
            - f32(np.exp(f32(s2 / den)))
            + f32(20.0)
            + f32(np.exp(f32(1.0)))
        )
        return [float(val)]
    if name == "rosenbrock":
        s = f32(0.0)
        for i in range(n - 1):
            diff = f32(x[i + 1] - f32(x[i] * x[i]))
            one = f32(f32(1.0) - x[i])
            s = f32(s + f32(f32(100.0) * f32(diff * diff)) + f32(one * one))
        return [float(s)]
    raise AssertionError(name)


def program_lines(text: str) -> list[str]:
    lines: list[str] = []
    for ln in text.splitlines():
        s = ln.strip()
        if not s or s.startswith("All terms check") or s.startswith("- "):
            continue
        lines.append(s)
    return lines


def parse_kv(body: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for tok in body.split():
        if "=" in tok:
            k, v = tok.split("=", 1)
            out[k] = v
    return out


class CatalogSmokeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        if np is None:
            raise unittest.SkipTest("numpy is not installed")
        if shutil.which("bend") is None:
            raise unittest.SkipTest("bend is not on PATH")
        proc = subprocess.run(
            ["bend", str(DRIVER)],
            check=False,
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            sys.stderr.write(proc.stderr or proc.stdout or "bend failed\n")
            raise AssertionError(f"bend {DRIVER} exited {proc.returncode}")
        cls.lines = program_lines(proc.stdout)

    def test_each_problem_evaluates_and_run_completes(self) -> None:
        by: dict[str, dict[str, str]] = {}
        for ln in self.lines:
            kind, name, rest = ln.split(" ", 2)
            by.setdefault(name, {})[kind] = rest
        self.assertEqual(set(by), set(DIMS))
        for name, (nv, nm, lo0, hi0, lo_l, hi_l) in DIMS.items():
            box = parse_kv(by[name]["box"])
            ev = parse_kv(by[name]["eval"])
            run = parse_kv(by[name]["run"])
            self.assertEqual(int(float(ev["nv"])), nv, name)
            self.assertEqual(int(float(ev["nm"])), nm, name)
            for key, expect in (("lo0", lo0), ("hi0", hi0), ("loL", lo_l), ("hiL", hi_l)):
                self.assertTrue(math.isclose(float(box[key]), expect, rel_tol=0.0, abs_tol=1e-5), f"{name} {key}")
            got = [float(p) for p in ev["f"].split(",") if p != ""]
            exp = reference(name)
            self.assertEqual(len(got), len(exp), name)
            for a, b in zip(got, exp):
                self.assertTrue(math.isfinite(a), name)
                self.assertTrue(
                    math.isclose(a, b, rel_tol=1e-4, abs_tol=1e-4),
                    f"{name} bend {a} ref {b}",
                )
            self.assertEqual(int(float(run["len"])), 4, name)
            self.assertGreaterEqual(int(float(run["nd"])), 1, name)


if __name__ == "__main__":
    raise SystemExit(unittest.main())
