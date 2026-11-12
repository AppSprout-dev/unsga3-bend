#!/usr/bin/env python3
"""Run list / Array.clone / Array.fork associate variants and report median ms/rep."""
from __future__ import annotations

import argparse
import json
import os
import statistics
import subprocess
import sys
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
KIND_NUM = {"list": 0, "clone": 1, "fork": 2}


def parse_output(text: str) -> dict:
    out: dict = {"raw": text}
    for line in text.splitlines():
        for tok in line.split():
            if "=" in tok:
                k, _, v = tok.partition("=")
                if k:
                    out[k.strip()] = v.strip()
    return out


def ms_per_rep(parsed: dict) -> float | None:
    try:
        total = float(parsed["total_ms"])
        reps = float(parsed["reps"])
        if reps <= 0:
            return None
        return total / reps
    except (KeyError, ValueError):
        return None


def run_one(cmd: list[str], env: dict) -> tuple[int, str, str]:
    proc = subprocess.run(cmd, cwd=HERE, env=env, text=True, capture_output=True)
    return proc.returncode, proc.stdout, proc.stderr


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--mode", choices=("interpret", "binary"), default="interpret")
    p.add_argument("--bang", action="store_true", help="compile/run the ! (Metal/GPU) maps")
    p.add_argument("--runs", type=int, default=5, help="independent process runs for the median")
    p.add_argument("--out-dir", type=Path, default=HERE / "results" / "array_clone_fork")
    p.add_argument(
        "--sizes",
        default="184,91,3,1,80;2048,276,3,1,10;32000,3003,3,1,2",
        help="n,r,m,warmup,reps semicolon-separated",
    )
    p.add_argument("--chunks", default="1,32,128")
    p.add_argument("--kinds", default="list,clone,fork")
    p.add_argument("--skip-32k", action="store_true")
    p.add_argument("--reuse-bin", action="store_true", help="skip compile if the binary already exists")
    args = p.parse_args()

    env = os.environ.copy()
    env["BEND_NO_TELEMETRY"] = "1"
    env["PATH"] = str(Path.home() / ".bend" / "bin") + os.pathsep + env.get("PATH", "")

    out_dir = args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    bend = env["PATH"].split(os.pathsep)[0] + "/bend"
    if not Path(bend).exists():
        bend = "bend"

    ver = subprocess.run([bend, "version"], capture_output=True, text=True, env=env)
    hostname = subprocess.run(["hostname"], capture_output=True, text=True)
    uname = subprocess.run(["uname", "-a"], capture_output=True, text=True)
    meta = {
        "bend_version": (ver.stdout or ver.stderr).strip(),
        "hostname": hostname.stdout.strip(),
        "uname": uname.stdout.strip(),
        "when": datetime.now().isoformat(timespec="seconds"),
        "mode": args.mode,
        "bang": bool(args.bang),
        "runs": args.runs,
        "method": (
            "median over independent process runs of (IO.now total_ms / in-process reps); "
            "+RTS --threads 1 when running a native binary"
        ),
    }
    print(json.dumps(meta, indent=2))

    sizes = []
    for chunk in args.sizes.split(";"):
        parts = [int(x) for x in chunk.split(",") if x.strip()]
        if len(parts) != 5:
            continue
        if args.skip_32k and parts[0] >= 32000:
            continue
        sizes.append(tuple(parts))
    chunks = [int(x) for x in args.chunks.split(",") if x.strip()]
    kinds = [k.strip() for k in args.kinds.split(",") if k.strip()]

    results = []
    for n, r, m, warmup, reps in sizes:
        for kind in kinds:
            kind_chunks = [1] if kind == "list" else chunks
            for chunk in kind_chunks:
                tag = f"{kind}_n{n}r{r}_c{chunk}_b{int(args.bang)}"
                wrapper = HERE / f"wrapper_array_{tag}.bend"
                subprocess.check_call(
                    [
                        sys.executable,
                        str(HERE / "write_array_wrapper.py"),
                        "--out",
                        str(wrapper),
                        "--kind",
                        kind,
                        "--chunk",
                        str(chunk),
                        "--n",
                        str(n),
                        "--r",
                        str(r),
                        "--m",
                        str(m),
                        "--seed",
                        "1",
                        "--warmup",
                        str(warmup),
                        "--reps",
                        str(reps),
                        "--dump",
                        "0",
                    ]
                    + (["--bang"] if args.bang else []),
                    cwd=HERE,
                    env=env,
                )
                binary = HERE / f"bin_array_{tag}"
                if args.mode == "binary" and (not args.reuse_bin or not binary.exists()):
                    compile_cmd = [bend, str(wrapper), "-o", str(binary)]
                    print(f"==== compile {tag} ====", flush=True)
                    cres = subprocess.run(compile_cmd, cwd=HERE, env=env, text=True, capture_output=True)
                    (out_dir / f"{tag}.compile.stdout.txt").write_text(cres.stdout)
                    (out_dir / f"{tag}.compile.stderr.txt").write_text(cres.stderr)
                    if cres.returncode != 0:
                        results.append(
                            {
                                "tag": tag,
                                "n": n,
                                "r": r,
                                "m": m,
                                "kind": kind,
                                "chunk": chunk,
                                "bang": bool(args.bang),
                                "error": "compile_failed",
                                "stderr": cres.stderr[-2000:],
                            }
                        )
                        print(cres.stderr[-1000:])
                        continue

                samples = []
                last = {}
                error = None
                for i in range(args.runs):
                    if args.mode == "binary":
                        cmd = [str(binary), "+RTS", "--threads", "1"]
                    else:
                        cmd = [bend, str(wrapper)]
                    print(f"==== run {tag} #{i+1}/{args.runs} ====", flush=True)
                    rc, stdout, stderr = run_one(cmd, env)
                    if rc != 0 and args.mode == "binary":
                        cmd = [str(binary), "--threads", "1"]
                        rc, stdout, stderr = run_one(cmd, env)
                    (out_dir / f"{tag}.run{i+1}.txt").write_text(stdout)
                    (out_dir / f"{tag}.run{i+1}.err").write_text(stderr)
                    parsed = parse_output(stdout)
                    parsed["rc"] = rc
                    last = parsed
                    ms = ms_per_rep(parsed)
                    print(stdout)
                    if stderr.strip():
                        print(stderr[-500:], file=sys.stderr)
                    if rc != 0:
                        error = f"run_failed rc={rc}: {stderr[-500:]}"
                        break
                    if ms is None:
                        error = "missing total_ms/reps"
                        break
                    samples.append(ms)

                rec = {
                    "tag": tag,
                    "n": n,
                    "r": r,
                    "m": m,
                    "kind": kind,
                    "chunk": None if kind == "list" else chunk,
                    "bang": bool(args.bang),
                    "warmup": warmup,
                    "reps": reps,
                    "runs_ok": len(samples),
                    "samples_ms_per_rep": samples,
                    "match_list": last.get("match_list"),
                    "sum_idx": last.get("sum_idx"),
                    "sum_idx_acc": last.get("sum_idx_acc"),
                    "n_asg": last.get("n_asg"),
                    "error": error,
                }
                if samples:
                    rec["median_ms_per_rep"] = statistics.median(samples)
                    rec["min_ms_per_rep"] = min(samples)
                    rec["max_ms_per_rep"] = max(samples)
                results.append(rec)
                print(json.dumps({k: rec[k] for k in rec if k != "samples_ms_per_rep"}))

    payload = {"meta": meta, "results": results}
    (out_dir / "results.json").write_text(json.dumps(payload, indent=2) + "\n")

    lines = [
        f"# Array.clone / Array.fork associate bench",
        "",
        f"- host: {meta['hostname']}",
        f"- uname: {meta['uname']}",
        f"- bend: {meta['bend_version']}",
        f"- mode: {meta['mode']}; bang={meta['bang']}",
        f"- when: {meta['when']}",
        f"- method: {meta['method']}",
        "",
        "| N x R x M | variant | chunk | backend | median ms/rep | min-max | runs x reps | match_list | sum_idx | notes |",
        "|---|---|---:|---|---:|---|---:|---|---:|---|",
    ]
    for rec in results:
        size = f"{rec['n']} x {rec['r']} x {rec['m']}"
        backend = "Metal/bang" if rec["bang"] else "CPU"
        chunk = "—" if rec["chunk"] is None else rec["chunk"]
        if rec.get("error"):
            lines.append(
                f"| {size} | {rec['kind']} | {chunk} | {backend} |  |  |  | {rec.get('match_list')} | {rec.get('sum_idx')} | {rec['error'][:80]} |"
            )
            continue
        med = rec["median_ms_per_rep"]
        lines.append(
            f"| {size} | {rec['kind']} | {chunk} | {backend} | {med:.4f} | {rec['min_ms_per_rep']:.4f}-{rec['max_ms_per_rep']:.4f} | {rec['runs_ok']} x {rec['reps']} | {rec.get('match_list')} | {rec.get('sum_idx')} | |"
        )
    (out_dir / "RESULTS.md").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
