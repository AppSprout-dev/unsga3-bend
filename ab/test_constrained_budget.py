#!/usr/bin/env python3
"""Native multi-gen OSY / TNK / C1-DTLZ1 must finish.

These are ``constrained_knobs`` (PymooCompatible, seed 1). The duplicating
CV insert overflowed this budget. The test builds
``bend src/constrained_budget.bend -o`` and requires one ``ok`` line per
problem, with the Run length equal to the population. No IGD.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from protocol import constrained_knobs

ROOT = Path(__file__).resolve().parent.parent
DRIVER = ROOT / "src" / "constrained_budget.bend"


def _fields(line: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for tok in line.split():
        if "=" in tok:
            key, val = tok.split("=", 1)
            out[key] = val
    return out


def _run() -> list[str]:
    bend = shutil.which("bend")
    if bend is None:
        raise unittest.SkipTest("bend is not on PATH")
    with tempfile.TemporaryDirectory() as tmp:
        binary = Path(tmp) / "constrained_budget"
        build = subprocess.run(
            [bend, str(DRIVER), "-o", str(binary)],
            check=False,
            capture_output=True,
            text=True,
        )
        if build.returncode != 0 or not binary.is_file():
            sys.stderr.write(build.stderr or build.stdout or "bend -o failed\n")
            raise AssertionError(f"bend -o exited {build.returncode}")
        proc = subprocess.run(
            [str(binary), "--threads", "1"],
            check=False,
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            sys.stderr.write(proc.stderr or proc.stdout or "binary failed\n")
            raise AssertionError(
                f"constrained budget binary exited {proc.returncode}: "
                f"{(proc.stderr or '').strip()}"
            )
        return [ln.strip() for ln in proc.stdout.splitlines() if ln.strip()]


class ConstrainedBudgetTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.lines = _run()
        cls.by_name = {}
        for ln in cls.lines:
            parts = ln.split()
            if len(parts) >= 2 and parts[0] == "ok":
                cls.by_name[parts[1]] = _fields(ln)

    def test_budgets_finish(self) -> None:
        for name in ("osy", "tnk", "c1dtlz1"):
            knobs = constrained_knobs(name)
            row = self.by_name[name]
            length = int(float(row["len"]))
            feas = int(float(row["feas"]))
            self.assertEqual(length, int(knobs["pop"]))
            self.assertEqual(int(float(row["pop"])), int(knobs["pop"]))
            self.assertEqual(int(float(row["gens"])), int(knobs["gens"]))
            self.assertGreaterEqual(feas, 1)
            self.assertLessEqual(feas, length)


if __name__ == "__main__":
    raise SystemExit(unittest.main())
