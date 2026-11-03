#!/usr/bin/env python3
"""Proof-wall gate for unsga3-bend, as CONTRIBUTING.md describes it.

`bend PROOF.bend` exits 1 even when the wall is closed, because Bend reports
the accepted @unsafe Das-Dennis defs as "SOME PROOFS FAIL". So the exit code
alone cannot be the verdict. This script passes only when:

  * PROOF.bend has 0 `?TODO` and Bend reports no TODO and no type error;
  * every `law X` in LAWS.bend has exactly one `def Laws.X` in PROOF.bend;
  * the @unsafe-tainted set from `bend PROOF.bend` equals EXPECTED_PROOF_UNSAFE,
    and from `bend src/lib.bend` equals EXPECTED_LIB_UNSAFE (CONTRIBUTING.md
    "Proof wall" names these);
  * `bend LAWS.bend --check-only` reports one TODO per law (open claims);
  * `bend challenges/NicheCountSum.challenge.bend` reports exactly `1 TODO found`.

It never edits LAWS.bend or PROOF.bend. A change in either expected set is a
finding to report (a new taint is a regression; a vanished taint means the
docs and this list need a reviewed update), not something to paper over.

Usage: check_proof_wall.py [--evidence DIR]   (exit 0 = wall as documented)
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(subprocess.check_output(
    ["git", "-C", str(Path(__file__).parent), "rev-parse", "--show-toplevel"], text=True).strip())

EXPECTED_PROOF_UNSAFE = {
    "src/reference_directions.nth_comp.go", "src/reference_directions.nth_comp",
    "src/reference_directions.nth_row", "src/reference_directions.comps_all",
    "src/reference_directions.das_dennis.from", "src/reference_directions.das_dennis",
    "src/algorithm.smoke_zdt1", "src/algorithm.oracle_zdt1", "src/algorithm.oracle_dtlz2",
    "src/algorithm.run_zdt1_smoke",
    "LAWS.das_dennis_m1_len", "LAWS.das_dennis_len", "comps_all_len", "das_ge2_len",
}
EXPECTED_LIB_UNSAFE = {
    "reference_directions.nth_comp.go", "reference_directions.nth_comp",
    "reference_directions.nth_row", "reference_directions.comps_all",
    "reference_directions.das_dennis.from", "reference_directions.das_dennis",
    "algorithm.smoke_zdt1", "algorithm.oracle_zdt1", "algorithm.oracle_dtlz2",
    "algorithm.run_zdt1_smoke", "das_dennis_m1",
}


def bend(*args: str) -> tuple[int, str]:
    p = subprocess.run(["bend", *args], cwd=ROOT, capture_output=True, text=True, timeout=900)
    return p.returncode, p.stdout + p.stderr


def unsafe_set(out: str) -> set[str]:
    # Bend 2.0.39+: "defs that depend on @unsafe: a, b, c"; 2.0.34: one "- name" per line.
    m = re.search(r"depend on @unsafe:\s*(.+)", out)
    if m:
        return {s.strip() for s in m.group(1).split(",") if s.strip()}
    if "rely on unsafe" in out:
        return {l[2:].strip() for l in out.splitlines() if l.startswith("- ")}
    return set()


def todo_count(out: str) -> int:
    m = re.search(r"(\d+) TODOs? found", out)
    return int(m.group(1)) if m else 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--evidence", type=Path)
    a = ap.parse_args()
    problems: list[str] = []

    laws = re.findall(r"^law ([A-Za-z0-9_]+)", (ROOT / "LAWS.bend").read_text(), re.M)
    proof_src = (ROOT / "PROOF.bend").read_text()
    proofs = re.findall(r"^def Laws\.([A-Za-z0-9_]+)", proof_src, re.M)
    if sorted(laws) != sorted(proofs):
        problems.append(f"law/proof mismatch: unproven={sorted(set(laws)-set(proofs))} "
                        f"orphan={sorted(set(proofs)-set(laws))} dup={len(proofs)-len(set(proofs))}")
    if "?TODO" in proof_src:
        problems.append(f"PROOF.bend contains {proof_src.count('?TODO')} ?TODO")

    runs = {}
    for key, args in {
        "proof": ("PROOF.bend",),
        "lib": ("src/lib.bend",),
        "laws": ("LAWS.bend", "--check-only"),
        "challenge": ("challenges/NicheCountSum.challenge.bend",),
    }.items():
        runs[key] = bend(*args)
        if a.evidence:
            a.evidence.mkdir(parents=True, exist_ok=True)
            rc, out = runs[key]
            (a.evidence / f"proofwall_{key}.log").write_text(f"$ bend {' '.join(args)}\nrc={rc}\n{out}")

    for key, expected in (("proof", EXPECTED_PROOF_UNSAFE), ("lib", EXPECTED_LIB_UNSAFE)):
        rc, out = runs[key]
        got = unsafe_set(out)
        if todo_count(out):
            problems.append(f"{key}: {todo_count(out)} TODO found")
        if got != expected:
            problems.append(f"{key}: unsafe set drift: new={sorted(got-expected)} gone={sorted(expected-got)}")
        other = [l for l in out.splitlines() if l.strip() and not (
            l.startswith(("SOME PROOFS FAIL", "Error: ", "defs that depend on @unsafe", "- ", "All terms check")))]
        # lib.bend's main prints nothing; anything else here is a checker error worth reading.
        if other:
            problems.append(f"{key}: unexpected output: {other[:5]}")

    n_laws = todo_count(runs["laws"][1])
    if n_laws != len(laws):
        problems.append(f"LAWS.bend --check-only: {n_laws} TODOs, expected {len(laws)} (one per law)")
    if todo_count(runs["challenge"][1]) != 1:
        problems.append(f"challenge: expected '1 TODO found', got: {runs['challenge'][1].strip()[:200]}")

    print(f"laws={len(laws)} proofs={len(proofs)} proof_todo={proof_src.count('?TODO')} "
          f"proof_unsafe={len(unsafe_set(runs['proof'][1]))} lib_unsafe={len(unsafe_set(runs['lib'][1]))} "
          f"laws_open={n_laws} challenge_todo={todo_count(runs['challenge'][1])}")
    for p in problems:
        print("FAIL", p)
    print("proof_wall=" + ("pass" if not problems else "fail"))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
