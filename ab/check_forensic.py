#!/usr/bin/env python3
"""Run checked-in Bend fixtures that lock forensic-audit behavior.

Prints one line per driver. Does not dump a Run front and does not
invent IGD, HV, or Wilcoxon numbers. Requires `bend` on PATH.
"""

from __future__ import annotations

import struct
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

CHECKER_PREFIXES = (
    "All terms check",
    "- ",
)

# (driver, expected stdout lines after the Bend checker banner)
CASES: list[tuple[Path, list[str]]] = [
    (
        ROOT / "src" / "trn_seed682.bend",
        [
            "ok rn682",
            "ok rn682_dist",
            "ok rn682_nocoin",
            "ok pymoo682",
            "ok niche_beats_dist",
            "ok rank_beats_dist",
            "ok coin_picks_farther",
        ],
    ),
    (
        ROOT / "src" / "g12_key.bend",
        [
            "g12 1,0.5,1.2346e-8",
            "raw 1.234567e-8",
        ],
    ),
]


def f32_bits(x: float) -> float:
    return struct.unpack("f", struct.pack("f", x))[0]


def g12_formats_differ() -> str | None:
    """C# G12 is 12 significant digits. Bend's locked key is 12 dp."""
    sig = format(f32_bits(1.234567e-8), ".12g")
    bend_key = "1.2346e-8"
    if sig == bend_key:
        return f"FAIL g12 divergence: .12g {sig!r} collapsed to the 12-dp key"
    return None


def program_lines(text: str) -> list[str]:
    lines: list[str] = []
    for ln in text.splitlines():
        s = ln.strip()
        if not s:
            continue
        if any(s.startswith(p) for p in CHECKER_PREFIXES):
            continue
        lines.append(s)
    return lines


def run_bend(path: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bend", str(path)],
        check=False,
        capture_output=True,
        text=True,
    )


def check_one(path: Path, expected: list[str]) -> str:
    rel = path.relative_to(ROOT)
    if not path.is_file():
        return f"FAIL {rel}: missing driver"
    proc = run_bend(path)
    if proc.returncode != 0:
        err = (proc.stderr or proc.stdout or "bend failed").strip()
        return f"FAIL {rel}: bend exit {proc.returncode}: {err}"
    got = program_lines(proc.stdout)
    if got != expected:
        return f"FAIL {rel}: got {got!r} expected {expected!r}"
    return f"ok {rel} ({len(expected)} lines)"


def main() -> int:
    fails = 0
    split = g12_formats_differ()
    if split is not None:
        print(split)
        fails += 1
    else:
        print("ok g12 .12g diverges from 12-dp key")
    for path, expected in CASES:
        line = check_one(path, expected)
        print(line)
        if not line.startswith("ok "):
            fails += 1
    return 1 if fails else 0


if __name__ == "__main__":
    raise SystemExit(main())
