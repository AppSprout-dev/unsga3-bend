#!/usr/bin/env bash
# Run the experimental associate benches on the Mac mini (Metal).
# Usage: ./run_mac_bench.sh
# Expects this directory to sit inside a unsga3-bend checkout (../../src).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
cd "$HERE"
mkdir -p results
export BEND_NO_TELEMETRY=1
export PATH="${HOME}/.bend/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH"

{
  echo "host=$(scutil --get ComputerName 2>/dev/null || hostname)"
  echo "date=$(date)"
  echo "uname=$(uname -a)"
  sysctl -n machdep.cpu.brand_string 2>/dev/null || true
  sysctl -n hw.memsize 2>/dev/null || true
  uptime
  command -v bend || true
  bend version || true
  command -v swiftc
  swiftc --version | head -1
  command -v clang
  clang --version | head -1
} | tee results/mac_env.txt

if ! command -v bend >/dev/null 2>&1; then
  echo "installing bend via install.sh"
  curl --proto '=https' --tlsv1.2 -fsSL https://bend-lang.com/install.sh | sh
  export PATH="${HOME}/.bend/bin:$PATH"
fi
# Use current Bend; never pin.
bend update || true
bend version | tee -a results/mac_env.txt

echo "==== compile Swift harness ===="
swiftc -O -o associate_harness AssociateHarness.swift -framework Metal -framework Foundation
echo "swiftc ok"

run_swift() {
  local n=$1 r=$2 m=$3 seed=$4 warmup=$5 reps=$6 tag=$7
  shift 7 || true
  local json="results/msl_${tag}.json"
  echo "==== hand MSL n=$n r=$r ===="
  if [ "$#" -gt 0 ]; then
    ./associate_harness --n "$n" --r "$r" --m "$m" --seed "$seed" \
      --warmup "$warmup" --reps "$reps" --metal associate.metal --json "$json" "$@"
  else
    ./associate_harness --n "$n" --r "$r" --m "$m" --seed "$seed" \
      --warmup "$warmup" --reps "$reps" --metal associate.metal --json "$json"
  fi
}

compile_bend() {
  local mode=$1 n=$2 r=$3 m=$4 seed=$5 warmup=$6 reps=$7 dump=$8 out=$9
  local bangflag=()
  if [ "$mode" = "bang" ]; then
    bangflag=(--bang)
  fi
  python3 write_wrapper.py --out "$HERE/wrapper_tmp.bend" "${bangflag[@]}" \
    --n "$n" --r "$r" --m "$m" --seed "$seed" --warmup "$warmup" --reps "$reps" --dump "$dump"
  echo "==== bend -o $out (mode=$mode) n=$n r=$r ===="
  bend "$HERE/wrapper_tmp.bend" -o "$out"
}

run_product() {
  local bin=$1 log=$2
  echo "==== run product $(basename "$bin") ===="
  if "$bin" +RTS --threads 1 > "$log" 2> "${log%.txt}.err"; then
    echo "product +RTS ok"
  elif "$bin" --threads 1 > "$log" 2> "${log%.txt}.err"; then
    echo "product legacy --threads ok"
  else
    echo "product run failed" >&2
    cat "${log%.txt}.err" >&2 || true
    return 1
  fi
  cat "$log"
}

run_bang_gpu() {
  local bin=$1 log=$2
  echo "==== run bang GPU $(basename "$bin") ===="
  if "$bin" +RTS --threads 1 > "$log" 2> "${log%.txt}.err"; then
    echo "bang GPU +RTS ok"
  elif "$bin" --threads 1 > "$log" 2> "${log%.txt}.err"; then
    echo "bang GPU legacy ok"
  else
    echo "bang GPU run failed" >&2
    cat "${log%.txt}.err" >&2 || true
    return 1
  fi
  cat "$log"
}

run_bang_cpu() {
  local bin=$1 log=$2
  echo "==== run bang --gpu off $(basename "$bin") ===="
  if "$bin" +RTS --threads 1 --gpu off > "$log" 2> "${log%.txt}.err"; then
    echo "bang --gpu off +RTS ok"
  elif "$bin" --threads 1 --gpu off > "$log" 2> "${log%.txt}.err"; then
    echo "bang --gpu off legacy ok"
  else
    echo "bang --gpu off failed (recorded, not fatal)" >&2
    cat "${log%.txt}.err" >&2 || true
    return 0
  fi
  cat "$log"
}

# Correctness fixture (matches ref_associate.py defaults).
run_swift 8 5 3 1 0 1 n8r5 --dump
python3 - << 'PY'
import json
from pathlib import Path
d = json.loads(Path("results/msl_n8r5.json").read_text())
dump = Path("results/msl_n8r5.dump.txt")
lines = ["ASSIGNMENTS"]
for i, x in zip(d["idx"], d["dist"]):
    lines.append(f"{i} {x}")
lines.append("COUNTS")
lines.append(" ".join(str(c) for c in d["counts"]))
dump.write_text("\n".join(lines) + "\n")
print(dump)
PY
python3 ref_associate.py --n 8 --r 5 --m 3 --seed 1 --compare results/msl_n8r5.dump.txt \
  > results/fixture_python_vs_msl.stdout.txt

# Realistic, mid, big-N.
#   184 x 91     : DTLZ2 combined parent+offspring pool (pop=92, p=12 -> 91 refs)
#   2048 x 276   : mid (p=23 -> 276 refs)
#   32000 x 3003 : Phase D go-big associate-shaped cell
SIZES="184 91 3 1 2 7 n184r91
2048 276 3 1 1 7 n2048r276
32000 3003 3 1 1 5 n32kr3003"

while read -r n r m seed warmup reps tag; do
  [ -n "${n:-}" ] || continue
  run_swift "$n" "$r" "$m" "$seed" "$warmup" "$reps" "$tag"

  compile_bend product "$n" "$r" "$m" "$seed" "$warmup" "$reps" 0 "$HERE/bin_product_$tag"
  run_product "$HERE/bin_product_$tag" "results/bend_product_${tag}.txt"

  compile_bend bang "$n" "$r" "$m" "$seed" "$warmup" "$reps" 0 "$HERE/bin_bang_$tag"
  run_bang_gpu "$HERE/bin_bang_$tag" "results/bend_bang_${tag}.txt"
  run_bang_cpu "$HERE/bin_bang_$tag" "results/bend_bangcpu_${tag}.txt"
done << EOF
$SIZES
EOF

python3 combine_results.py
echo "==== all benches done ===="
ls -l results
