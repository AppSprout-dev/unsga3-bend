# Proof wall

`LAWS.bend` holds 31 human-owned claims, and `PROOF.bend` closes each one with a `def Laws.<name>`. The gate is `bend PROOF.bend`. It must show 0 `?TODO`. The only taint allowed is the documented set of `@unsafe` Das–Dennis defs.

## Sub-features

- `wall-closed`: every `law X` has exactly one `def Laws.X`, and PROOF.bend has 0 `?TODO`.
- `wall-unsafe-set`: the `@unsafe` taint is exactly the 14 names from `bend PROOF.bend` and the 11 from `bend src/lib.bend`.
- `wall-laws-open`: `bend LAWS.bend --check-only` reports one TODO per law.
- `wall-challenge`: `challenges/NicheCountSum.challenge.bend` still has exactly one hole.

## How to get to it (user POV)

- `bend PROOF.bend` (AGENTS.md: run it before committing).
- `bend src/lib.bend` (module graph).
- `bend LAWS.bend --check-only` and `bend challenges/NicheCountSum.challenge.bend`.

## Driving it with bend + ab scripts

Preconditions: `bend` is on PATH. Nothing else is needed.

- **Wall verdict.** Run `python3 .cursor/skills/verify-unsga3-bend/scripts/check_proof_wall.py --evidence "$EVIDENCE/gates"`. The last line is `proof_wall=pass`, and the summary reads `laws=31 proofs=31 proof_todo=0 proof_unsafe=14 lib_unsafe=11 laws_open=31 challenge_todo=1`.
- **Raw output.** Read `$EVIDENCE/gates/proofwall_proof.log`. It shows `rc=1`, `SOME PROOFS FAIL`, and `14 defs rely on unsafe or foreign code`, and it has no `TODO found` line.
- **Checker self-test.** Run `python3 .cursor/skills/verify-unsga3-bend/scripts/check_proof_wall.py --self-test`. Every line starts with `ok`, and the last line is `self_test=pass`. It covers synthetic outputs (a type error next to an intact taint list, `Error: <msg>`, `- expected` lines, a wrong header count) and temp-dir copies with a planted `?TODO` and a planted type error in `Laws.niche_count_sum`. All of those must fail while the clean copy passes.
- **Kernel recheck (optional).** `bend PROOF.bend --verdict` gives the same output and the same unsafe list.

## Gotchas

- A type error prints a bare `Error:` followed by `- expected :` / `- observed :` / `Context:` / `Location:` lines, and the @unsafe taint list disappears. The checker treats any of those lines as a failure.
- The exit code is 1 even when the wall is closed. Never report "PROOF fails" from the exit code alone, and never report "PROOF passes" without checking the unsafe set.
- Bend 2.0.34 prints the tainted names one per line (`- name`). 2.0.39 prints them comma-separated after `defs that depend on @unsafe:`. The checker parses both.
- The law count (31) is read from LAWS.bend, not hard-coded. Changing the expected unsafe sets in the checker needs the same reviewed reason as a CONTRIBUTING.md "Proof wall" change.
- What the wall buys, and what it doesn't (no simplex membership, front identity, or IGD), is in CONTRIBUTING.md and docs/PROOF-SURFACE.md. Don't widen public verbs past that.
