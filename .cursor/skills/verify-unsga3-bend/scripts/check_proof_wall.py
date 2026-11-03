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

Bend output is parsed strictly. The only non-taint lines allowed are
`SOME PROOFS FAIL`, `Error: <N> defs rely on unsafe or foreign code:` (N must
equal the number of names listed), and the names themselves: one
`defs that depend on @unsafe: a, b` line (2.0.39+) or `- name` lines right
after the header (2.0.34). Any other line, including a type error's
`Error:` / `- expected :` block, fails the wall.

Usage:
  check_proof_wall.py [--evidence DIR] [--root DIR]   exit 0 = wall as documented
  check_proof_wall.py --self-test                     parser cases plus planted
      ?TODO and planted type-error copies in a temp dir; exit 0 = every case
      gave the expected verdict
"""
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
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


def bend(root: Path, *args: str) -> tuple[int, str]:
    p = subprocess.run(["bend", *args], cwd=root, capture_output=True, text=True, timeout=900)
    return p.returncode, p.stdout + p.stderr


TAINT_HEADER = re.compile(r"^Error: (\d+) defs rely on unsafe or foreign code:$")
TAINT_LIST_239 = re.compile(r"^defs that depend on @unsafe: (.+)$")
TAINT_ITEM_234 = re.compile(r"^- ([A-Za-z0-9_./]+)$")


def parse_taint(out: str) -> tuple[set[str], list[str]]:
    """Return (tainted names, unexpected lines) for a `bend <file>` run that
    should fail only because of @unsafe taint. Unexpected lines fail the wall."""
    names: list[str] = []
    unexpected: list[str] = []
    header_n: int | None = None
    in_list = False
    for line in out.splitlines():
        if not line.strip():
            in_list = False
            continue
        if line == "SOME PROOFS FAIL" or line.startswith("All terms check"):
            in_list = False
            continue
        m = TAINT_HEADER.match(line)
        if m and header_n is None:
            header_n, in_list = int(m.group(1)), True
            continue
        m = TAINT_LIST_239.match(line)
        if m and in_list and not names:
            names += [x.strip() for x in m.group(1).split(",") if x.strip()]
            in_list = False
            continue
        m = TAINT_ITEM_234.match(line)
        if m and in_list:
            names.append(m.group(1))
            continue
        in_list = False
        unexpected.append(line)
    if header_n is not None and header_n != len(names):
        unexpected.append(f"(taint header says {header_n} defs, listed {len(names)})")
    if header_n is None and names:
        unexpected.append("(taint names without the taint header)")
    return set(names), unexpected


def unsafe_set(out: str) -> set[str]:
    return parse_taint(out)[0]


def todo_count(out: str) -> int:
    m = re.search(r"(\d+) TODOs? found", out)
    return int(m.group(1)) if m else 0


TODO_OK = re.compile(r"^(SOME PROOFS FAIL|Error: \d+ TODOs? found\.|The code is incomplete, and not a valid proof yet\.)$")


def todo_only_unexpected(out: str) -> list[str]:
    """Lines other than Bend's plain TODO report (for files that should be open holes only)."""
    return [l for l in out.splitlines() if l.strip() and not TODO_OK.match(l)]


def check(root: Path, evidence: Path | None = None) -> tuple[str, list[str]]:
    problems: list[str] = []
    laws = re.findall(r"^law ([A-Za-z0-9_]+)", (root / "LAWS.bend").read_text(), re.M)
    proof_src = (root / "PROOF.bend").read_text()
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
        runs[key] = bend(root, *args)
        if evidence:
            evidence.mkdir(parents=True, exist_ok=True)
            rc, out = runs[key]
            (evidence / f"proofwall_{key}.log").write_text(f"$ bend {' '.join(args)}\nrc={rc}\n{out}")

    for key, expected in (("proof", EXPECTED_PROOF_UNSAFE), ("lib", EXPECTED_LIB_UNSAFE)):
        rc, out = runs[key]
        got, other = parse_taint(out)
        if todo_count(out):
            problems.append(f"{key}: {todo_count(out)} TODO found")
        if got != expected:
            problems.append(f"{key}: unsafe set drift: new={sorted(got-expected)} gone={sorted(expected-got)}")
        # lib.bend's main prints nothing; anything else is a checker error worth reading.
        if other:
            problems.append(f"{key}: unexpected output: {other[:5]}")

    n_laws = todo_count(runs["laws"][1])
    if n_laws != len(laws):
        problems.append(f"LAWS.bend --check-only: {n_laws} TODOs, expected {len(laws)} (one per law)")
    if todo_count(runs["challenge"][1]) != 1:
        problems.append(f"challenge: expected '1 TODO found', got: {runs['challenge'][1].strip()[:200]}")
    for key in ("laws", "challenge"):
        other = todo_only_unexpected(runs[key][1])
        if other:
            problems.append(f"{key}: unexpected output: {other[:5]}")

    summary = (f"laws={len(laws)} proofs={len(proofs)} proof_todo={proof_src.count('?TODO')} "
               f"proof_unsafe={len(unsafe_set(runs['proof'][1]))} lib_unsafe={len(unsafe_set(runs['lib'][1]))} "
               f"laws_open={n_laws} challenge_todo={todo_count(runs['challenge'][1])}")
    return summary, problems


# --- self-test -------------------------------------------------------------

_NAMES = sorted(EXPECTED_PROOF_UNSAFE)
_TAINT_239 = ("SOME PROOFS FAIL\nError: 14 defs rely on unsafe or foreign code:\n"
              "defs that depend on @unsafe: " + ", ".join(_NAMES) + "\n")
_TAINT_234 = ("SOME PROOFS FAIL\nError: 14 defs rely on unsafe or foreign code:\n"
              + "".join(f"- {n}\n" for n in _NAMES))
_TYPE_ERR = ("Error:\n- expected : {A == B : Nat}\n- observed : Nat\nContext:\n- asgs   : List<&2, X>\n"
             "Location: Laws.niche_count_sum\n")

# (name, synthetic `bend PROOF.bend` output, wall must pass?)
PARSER_CASES = [
    ("taint only, 2.0.39 shape", _TAINT_239, True),
    ("taint only, 2.0.34 shape", _TAINT_234, True),
    ("taint + bare Error: type error", _TAINT_239 + _TYPE_ERR, False),
    ("taint + 'Error: <msg>' line", _TAINT_239 + "Error: Type mismatch in Laws.x\n", False),
    ("2.0.34 taint + '- expected' lines", _TAINT_234 + "- expected : Nat\n- observed : Bool\n", False),
    ("header count != names listed", _TAINT_239.replace("Error: 14", "Error: 15"), False),
    ("second taint-shaped Error line", _TAINT_239 + "Error: 3 defs rely on unsafe or foreign code:\n", False),
]


def _copy_tree(src: Path, dst: Path) -> None:
    files = subprocess.check_output(["git", "-C", str(src), "ls-files", "-z"], text=True).split("\0")
    for f in filter(None, files):
        s, d = src / f, dst / f
        if s.is_file():
            d.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(s, d)


def _plant(root: Path, old: str, new: str) -> None:
    p = root / "PROOF.bend"
    src = p.read_text()
    if old not in src:
        raise SystemExit(f"self-test: plant anchor not found in PROOF.bend: {old!r}")
    p.write_text(src.replace(old, new, 1))


PLANT_ANCHOR = "  count_raw_sum(n_dirs, Util.list_len(Surv.Assignment, asgs), asgs)"
# (name, replacement for PLANT_ANCHOR or None for the clean copy, wall must pass?)
TREE_CASES = [
    ("clean copy", None, True),
    ("planted ?TODO in Laws.niche_count_sum", "  ?TODO", False),
    ("planted type error in Laws.niche_count_sum", "  Util.list_len(Surv.Assignment, asgs)", False),
]


def self_test() -> int:
    bad = 0
    for name, out, want_pass in PARSER_CASES:
        got, other = parse_taint(out)
        passed = got == EXPECTED_PROOF_UNSAFE and not other
        ok = passed == want_pass
        bad += not ok
        print(f"{'ok ' if ok else 'BAD'} parser: {name}: wall={'pass' if passed else 'fail'} (want {'pass' if want_pass else 'fail'})")
    for name, new, want_pass in TREE_CASES:
        with tempfile.TemporaryDirectory(prefix="proofwall-selftest-") as td:
            root = Path(td)
            _copy_tree(ROOT, root)
            if new is not None:
                _plant(root, PLANT_ANCHOR, new)
            summary, problems = check(root)
        passed = not problems
        ok = passed == want_pass
        bad += not ok
        print(f"{'ok ' if ok else 'BAD'} tree: {name}: wall={'pass' if passed else 'fail'} (want {'pass' if want_pass else 'fail'})")
        for pr in problems[:3]:
            print(f"      FAIL {pr[:220]}")
    print("self_test=" + ("pass" if not bad else f"fail ({bad} case(s) gave the wrong verdict)"))
    return 1 if bad else 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--evidence", type=Path)
    ap.add_argument("--root", type=Path, default=ROOT, help="tree to check (default: this checkout)")
    ap.add_argument("--self-test", action="store_true",
                    help="parser cases + planted ?TODO / type-error copies; never touches the checkout")
    a = ap.parse_args()
    if a.self_test:
        return self_test()
    summary, problems = check(a.root.resolve(), a.evidence)
    print(summary)
    for p in problems:
        print("FAIL", p)
    print("proof_wall=" + ("pass" if not problems else "fail"))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
