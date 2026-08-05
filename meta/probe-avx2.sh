#!/bin/sh
# Print 1 only when the configured compiler targets x86 and accepts AVX2.
set -eu

compiler=${CXX:-c++}
flags=${AVX2_FLAGS:--mavx2}
tmp=$(mktemp -d "${TMPDIR:-/tmp}/dragmap-avx2-XXXXXX")
trap 'rm -rf "$tmp"' EXIT INT HUP TERM
printf 'int main(void) { return 0; }\n' > "$tmp/probe.cpp"

# Testing an ISA flag is not target classification: some Apple clang versions
# accept x86 flags on arm64 with an ignored-argument warning.
if ! $compiler -dM -E -x c++ "$tmp/probe.cpp" > "$tmp/macros" 2>/dev/null; then
  printf '0\n'
  exit 0
fi
if ! grep -Eq '^#define (__x86_64__|__i386__|_M_X64|_M_IX86)( |$)' "$tmp/macros"; then
  printf '0\n'
  exit 0
fi

# shellcheck disable=SC2086
if $compiler -Werror $flags -c "$tmp/probe.cpp" -o "$tmp/probe.o" >/dev/null 2>&1; then
  printf '1\n'
else
  printf '0\n'
fi
