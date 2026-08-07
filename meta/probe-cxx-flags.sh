#!/bin/sh
# Print the requested C++ flags accepted by the configured compiler.
set -eu

compiler=${CXX:-c++}
flags=${CXX_FLAGS_TO_PROBE:-}
tmp=$(mktemp -d "${TMPDIR:-/tmp}/dragmap-cxx-flags-XXXXXX")
trap 'rm -rf "$tmp"' EXIT INT HUP TERM
printf 'int main() { return 0; }\n' > "$tmp/probe.cpp"

supported=
for flag in $flags; do
  # CXX may intentionally contain a compiler command plus wrapper arguments.
  # shellcheck disable=SC2086
  if $compiler -Werror "$flag" -x c++ -c "$tmp/probe.cpp" -o "$tmp/probe.o" >/dev/null 2>&1; then
    supported="${supported}${supported:+ }$flag"
  fi
done
printf '%s\n' "$supported"
