#!/usr/bin/env bash
# Read-only: is this checkout + toolchain worth verifying? Exit 0 = required tools present.
# Optional oracles (pymoo, dotnet + UNSGA3_CS_ROOT) only print a status; their scripts skip without them.
set -u
ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
fail=0
say() { printf '%-14s %s\n' "$1" "$2"; }

say repo "$ROOT"
say head "$(git -C "$ROOT" rev-parse HEAD) ($(git -C "$ROOT" log -1 --format=%cI))"
say branch "$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"
dirty=$(git -C "$ROOT" status --porcelain --untracked-files=no | wc -l)
say tracked-dirty "$dirty file(s)"

if command -v bend >/dev/null; then say bend "$(bend version) at $(command -v bend)"
else say bend "MISSING (export PATH=\"\$HOME/.bend/bin:\$PATH\")"; fail=1; fi
[ "${BEND_NO_TELEMETRY:-}" = 1 ] || say telemetry "BEND_NO_TELEMETRY not set (set it to 1)"

if command -v clang >/dev/null; then
  v=$(clang --version | head -1); major=$(printf '%s' "$v" | sed -E 's/.*version ([0-9]+).*/\1/')
  if [ "${major:-0}" -ge 14 ] 2>/dev/null; then say clang "$v"; else say clang "TOO OLD: $v (need 14+)"; fail=1; fi
else say clang "MISSING (native -o builds fail; see SKILL.md Launch for the shim)"; fail=1; fi

command -v python3 >/dev/null && say python3 "$(python3 --version 2>&1)" || { say python3 MISSING; fail=1; }
if python3 -c 'import numpy' 2>/dev/null; then say numpy ok; else say numpy "MISSING (ab/ tests need it)"; fail=1; fi
pv=$(python3 -c 'import pymoo;print(pymoo.__version__)' 2>/dev/null) && say pymoo "$pv" || say pymoo "absent (IGD + pymoo column print skip:)"
if command -v dotnet >/dev/null; then say dotnet "$(dotnet --version 2>/dev/null)"; else say dotnet "absent (C# column prints skip:)"; fi
if [ -n "${UNSGA3_CS_ROOT:-}" ]; then
  if [ -d "$UNSGA3_CS_ROOT/tools/OracleCompare" ]; then
    case "$(cd "$UNSGA3_CS_ROOT" && pwd)/" in "$ROOT"/*) say cs-root "INSIDE this repo: refuse (never vendor Unsga3)"; fail=1;;
      *) say cs-root "$UNSGA3_CS_ROOT ok";; esac
  else say cs-root "$UNSGA3_CS_ROOT has no tools/OracleCompare"; fi
else say cs-root "unset (C# column prints skip:)"; fi
exit $fail
