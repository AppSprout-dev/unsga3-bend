#!/usr/bin/env bash
# Verification scaffolding only. When no clang 14+ can be installed (no apt mirror, no sudo),
# put zig's bundled clang on PATH as `clang`. Usage:
#   eval "$(.cursor/skills/verify-unsga3-bend/scripts/zig_clang_shim.sh /tmp/unsga3-bend-verify/toolchain)"
# Prints an `export PATH=...` line. Remove the dir in cleanup; never commit it.
set -eu
DIR=${1:?usage: zig_clang_shim.sh <scratch-dir>}
mkdir -p "$DIR"
[ -x "$DIR/venv/bin/python" ] || python3 -m venv "$DIR/venv" >&2
"$DIR/venv/bin/pip" -q install ziglang >&2
mkdir -p "$DIR/bin"
printf '#!/bin/sh\nexec "%s" -m ziglang cc "$@"\n' "$DIR/venv/bin/python" > "$DIR/bin/clang"
chmod +x "$DIR/bin/clang"
"$DIR/bin/clang" --version | head -1 >&2
echo "export PATH=\"$DIR/bin:\$PATH\""
