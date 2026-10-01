#!/usr/bin/env python3
"""OSY / TNK / C1-DTLZ1 formulation and survival smoke.

Builds ``bend src/constrained_smoke.bend -o`` and runs the binary.
Bend 2.0.34's interpreter faults when that driver's three Runs share
``main``; the native binary is the checked path. No IGD.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DRIVER = ROOT / "src" / "constrained_smoke.bend"


def _parse_nums(text: str) -> list[float]:
    if text.strip() == "":
        return []
    return [float(part) for part in text.split(",") if part != ""]


def _run() -> list[str]:
    bend = shutil.which("bend")
    if bend is None:
        raise unittest.SkipTest("bend is not on PATH")
    with tempfile.TemporaryDirectory() as tmp:
        binary = Path(tmp) / "constrained_smoke"
        build = subprocess.run(
            [bend, str(DRIVER), "-o", str(binary)],
            check=False,
            capture_output=True,
            text=True,
        )
        if build.returncode != 0 or not binary.is_file():
            sys.stderr.write(build.stderr or build.stdout or "bend -o failed\n")
            raise AssertionError(f"bend -o exited {build.returncode}")
        proc = subprocess.run([str(binary)], check=False, capture_output=True, text=True)
        if proc.returncode != 0:
            sys.stderr.write(proc.stderr or proc.stdout or "binary failed\n")
            raise AssertionError(f"constrained smoke binary exited {proc.returncode}")
        return [ln.strip() for ln in proc.stdout.splitlines() if ln.strip()]


def _fields(line: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for tok in line.split():
        if "=" in tok:
            key, val = tok.split("=", 1)
            out[key] = val
    return out


class ConstrainedSmokeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.lines = _run()
        cls.by_name = {}
        for ln in cls.lines:
            parts = ln.split()
            if len(parts) >= 2 and parts[0] in ("pt", "surv", "run"):
                cls.by_name[parts[0] + " " + parts[1]] = _fields(ln)

    def test_osy_points(self) -> None:
        feas = self.by_name["pt osy_feas"]
        self.assertEqual(_parse_nums(feas["f"]), [-274.0, 76.0])
        g = _parse_nums(feas["g"])
        self.assertEqual(len(g), 6)
        self.assertEqual(g[0], -2.0)
        self.assertEqual(g[2], -3.0)
        self.assertTrue(all(v == 0.0 for v in (g[1], g[3], g[4], g[5])))
        self.assertEqual(float(feas["cv"]), 0.0)
        self.assertEqual(feas["feas"], "1")
        self.assertEqual(feas["nv"], "6")
        self.assertEqual(feas["ng"], "6")
        lo = self.by_name["pt osy_lo"]
        self.assertEqual(_parse_nums(lo["f"]), [-120.0, 2.0])
        self.assertEqual(_parse_nums(lo["g"])[0], 1.0)
        self.assertEqual(float(lo["cv"]), 1.0)
        self.assertEqual(lo["feas"], "0")

    def test_tnk_points(self) -> None:
        feas = self.by_name["pt tnk_feas"]
        self.assertEqual(_parse_nums(feas["f"]), [1.0, 1.0])
        g = _parse_nums(feas["g"])
        self.assertAlmostEqual(g[0], -0.9, places=5)
        self.assertEqual(g[1], 0.0)
        self.assertEqual(feas["feas"], "1")
        near = self.by_name["pt tnk_near"]
        self.assertAlmostEqual(_parse_nums(near["g"])[0], 1.08, places=5)
        self.assertLess(_parse_nums(near["g"])[1], 0.0)
        self.assertAlmostEqual(float(near["cv"]), 1.08, places=5)
        self.assertEqual(near["feas"], "0")

    def test_c1_points(self) -> None:
        feas = self.by_name["pt c1_feas"]
        f = _parse_nums(feas["f"])
        self.assertEqual(len(f), 3)
        self.assertAlmostEqual(f[0], 0.125, places=5)
        self.assertAlmostEqual(f[1], 0.125, places=5)
        self.assertAlmostEqual(f[2], 0.25, places=5)
        self.assertAlmostEqual(_parse_nums(feas["g"])[0], -1.0 / 12.0, places=5)
        self.assertEqual(feas["feas"], "1")
        self.assertEqual(feas["nv"], "7")
        self.assertEqual(feas["ng"], "1")
        bad = self.by_name["pt c1_bad"]
        self.assertEqual(bad["feas"], "0")
        self.assertGreater(float(bad["cv"]), 1.0)

    def test_survival_keeps_feasible_ideal_and_lower_cv(self) -> None:
        osy = self.by_name["surv osy"]
        self.assertEqual(osy["s0f"], "1")
        self.assertEqual(osy["s1f"], "0")
        self.assertEqual(float(osy["s1cv"]), 1.0)
        self.assertEqual(osy["s1lnk"], "0")
        self.assertEqual(_parse_nums(osy["ideal"]), [-274.0, 76.0])
        tnk = self.by_name["surv tnk"]
        self.assertEqual(tnk["s0f"], "1")
        self.assertEqual(tnk["s1lnk"], "0")
        self.assertAlmostEqual(float(tnk["s1cv"]), 1.08, places=5)
        self.assertEqual(_parse_nums(tnk["ideal"]), [1.0, 1.0])
        c1 = self.by_name["surv c1"]
        self.assertEqual(c1["s0f"], "1")
        self.assertEqual(c1["s1f"], "0")
        self.assertEqual(c1["s1lnk"], "0")
        ideal = _parse_nums(c1["ideal"])
        self.assertAlmostEqual(ideal[0], 0.125, places=5)
        self.assertAlmostEqual(ideal[1], 0.125, places=5)
        self.assertAlmostEqual(ideal[2], 0.25, places=5)
        self.assertLess(float(c1["s1cv"]), 100.0)

    def test_seeded_runs_keep_a_feasible_member(self) -> None:
        for name, nm in (("osy", "2"), ("tnk", "2"), ("c1", "3")):
            fields = self.by_name["run " + name]
            self.assertEqual(fields["len"], "12")
            self.assertGreaterEqual(int(float(fields["feas"])), 1)
            self.assertEqual(fields["nm"], nm)


if __name__ == "__main__":
    raise SystemExit(unittest.main())
