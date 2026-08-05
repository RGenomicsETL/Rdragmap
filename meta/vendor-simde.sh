#!/bin/sh
# Refresh the pinned header-only SIMDe source used by DRAGMAP portability code.
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
commit=f3e8262173b7089db9a9d57a9ecef8dd07ad9c97
repo=https://github.com/simd-everywhere/simde.git
tmp=$(mktemp -d "${TMPDIR:-/tmp}/rdragmap-simde-XXXXXX")
trap 'rm -rf "$tmp"' EXIT INT HUP TERM

git clone --quiet --no-checkout "$repo" "$tmp/simde"
git -C "$tmp/simde" fetch --quiet --depth=1 origin "$commit"
git -C "$tmp/simde" checkout --quiet --detach "$commit"
test "$(git -C "$tmp/simde" rev-parse HEAD)" = "$commit"

rm -rf "$root/thirdparty/simde/simde"
mkdir -p "$root/thirdparty/simde"
cp -R "$tmp/simde/simde" "$root/thirdparty/simde/simde"
cp "$tmp/simde/COPYING" "$root/thirdparty/simde/COPYING"
cp "$tmp/simde/README.md" "$root/thirdparty/simde/README.md"

git -C "$root" apply "$root/meta/patches/0001-simde-remove-diagnostic-pragmas.patch"
cat > "$root/thirdparty/simde/VERSION" <<EOF
Component: SIMDe
Version: 0.8.4
Repository: https://github.com/simd-everywhere/simde
Commit: $commit
Date: 2026-05-10
Vendored-include-tree: thirdparty/simde/simde
License-file: thirdparty/simde/COPYING
EOF

printf 'Vendored SIMDe %s\n' "$commit"
