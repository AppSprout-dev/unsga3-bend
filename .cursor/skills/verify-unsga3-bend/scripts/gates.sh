#!/usr/bin/env bash
# Run the CONTRIBUTING.md "Check the tree" gates plus the proof wall and a native/interpreter
# parity check on the checked-in ZDT1 smoke. One log per gate under $EVIDENCE/gates.
# Usage: EVIDENCE=/tmp/unsga3-bend-verify/<run-id> .cursor/skills/verify-unsga3-bend/scripts/gates.sh
# Exit 0 only if every gate passed.
set -u
ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
HERE=$(cd "$(dirname "$0")" && pwd)
EVIDENCE=${EVIDENCE:-/tmp/unsga3-bend-verify/$(date +%Y%m%dT%H%M%S)}
mkdir -p "$EVIDENCE/gates"
cd "$ROOT"
export BEND_NO_TELEMETRY=1
fails=0
{ echo "head=$(git rev-parse HEAD)"; echo "bend=$(bend version)"; echo "clang=$(clang --version 2>/dev/null | head -1)"; date -Is; } > "$EVIDENCE/gates/env.txt"

gate() {  # gate <name> <cmd...>; pass = exit 0
  local name=$1; shift
  local log="$EVIDENCE/gates/$name.log"
  local t0=$(date +%s)
  { echo "\$ $*"; "$@"; } > "$log" 2>&1; local rc=$?
  local verdict=pass; [ $rc -eq 0 ] || { verdict=FAIL; fails=$((fails+1)); }
  printf '%-16s %-4s rc=%-3s %4ss  %s\n' "$name" "$verdict" "$rc" "$(( $(date +%s)-t0 ))" "$(tail -1 "$log")" | tee -a "$EVIDENCE/gates/summary.txt"
}

gate proof_wall      python3 "$HERE/check_proof_wall.py" --evidence "$EVIDENCE/gates"
gate op_smoke        bend src/op_smoke.bend
gate run_smoke       bend src/run_smoke.bend
gate catalog_smoke   bend src/catalog_smoke.bend
gate ab_select       bend src/ab_select.bend
gate check_forensic  python3 ab/check_forensic.py
gate dump_defaults   python3 ab/test_dump_defaults.py
gate catalog_smoke_t python3 ab/test_catalog_smoke.py
gate catalog_proto_t python3 ab/test_catalog_protocol.py
gate gd_plus_t       python3 ab/test_gd_plus.py
gate constrained_t   python3 ab/test_constrained_smoke.py
gate constr_budget_t python3 ab/test_constrained_budget.py
gate dump_front      python3 ab/dump_bend_front.py
gate dump_run_native python3 ab/dump_bend_run.py --native --out "$EVIDENCE/gates/bend_run_F_native.csv"
gate dump_run_interp python3 ab/dump_bend_run.py --interpreter --out "$EVIDENCE/gates/bend_run_F_interp.csv"
# Native and interpreter must write the same smoke front (same seed, same RNG order).
gate native_parity   cmp "$EVIDENCE/gates/bend_run_F_native.csv" "$EVIDENCE/gates/bend_run_F_interp.csv"
# The native dump must have run a binary (fresh build or cache hit), not silently fallen back to the interpreter.
gate native_built    grep -E "native: (compile_s=|cache hit)" "$EVIDENCE/gates/dump_run_native.log"

echo "evidence=$EVIDENCE/gates failed=$fails" | tee -a "$EVIDENCE/gates/summary.txt"
exit $(( fails > 0 ))
