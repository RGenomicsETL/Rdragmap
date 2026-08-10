#!/bin/sh
# Print the requested C flags accepted by the configured compiler.
set -eu

compiler=${CC:-cc}
flags=${C_FLAGS_TO_PROBE:-}
tmp=$(mktemp -d "${TMPDIR:-/tmp}/dragmap-c-flags-XXXXXX")
trap 'rm -rf "$tmp"' EXIT INT HUP TERM
printf 'int main(void) { return 0; }\n' > "$tmp/probe.c"

supported=
for flag in $flags; do
  # CC may intentionally contain a compiler command plus wrapper arguments.
  # shellcheck disable=SC2086
  if $compiler -Werror "$flag" -x c -c "$tmp/probe.c" -o "$tmp/probe.o" >/dev/null 2>&1; then
    supported="${supported}${supported:+ }$flag"
  fi
done
printf '%s\n' "$supported"
