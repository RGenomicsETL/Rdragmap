#!/bin/sh
# Compile the portable native source with strict warnings and audit every
# deliberately non-standard diagnostic against the checked-in baseline.
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
baseline="$root/meta/pedantic-warnings.txt"
work=$(mktemp -d "${TMPDIR:-/tmp}/rdragmap-pedantic.XXXXXX")
log="$work/build.log"
expected="$work/expected.txt"
actual="$work/warnings.txt"
trap 'rm -rf "$work"' EXIT INT HUP TERM

if [ ! -f "$baseline" ]; then
  echo "missing pedantic warning baseline: $baseline" >&2
  exit 1
fi

# Pedantic warnings are enabled for every translation unit. Existing imported
# GNU-layout extensions are demoted only long enough to compare their exact
# file-and-warning baseline below. All other warnings remain errors.
cxx_warnings='-Werror -Wno-unused-variable -Wno-free-nonheap-object -Wno-parentheses -Wpedantic -Wno-error=pedantic -Wno-error=vla -Wno-error=overflow'
c_warnings='-Werror -Wno-unused-variable -Wno-unused-function -Wno-format-truncation -Wpedantic -Wno-error=pedantic'
if ! (
  unset CFLAGS CXXFLAGS CPPFLAGS
  make -C "$root" -j1 \
    HAS_GTEST=0 DRAGMAP_HAVE_AVX2=0 \
    DRAGEN_OS_BUILD_DIR_BASE="$work/build" \
    CXXWARNINGS="$cxx_warnings" CWARNINGS="$c_warnings" \
    native-libraries check-debug-header >"$log" 2>&1
); then
  sed -n '1,240p' "$log" >&2
  exit 1
fi

sed '/^#/d; /^$/d' "$baseline" >"$expected"
sed -nE 's#^(.+):[0-9]+:[0-9]+: warning:.*(\[-W[^]]+\])$#\1 \2#p' "$log" |
  sed "s#^$root/##" |
  sort -u >"$actual"

if ! diff -u "$expected" "$actual"; then
  echo "unreviewed pedantic diagnostics; update source or the audited baseline" >&2
  exit 1
fi

echo "Pedantic native audit passed."
