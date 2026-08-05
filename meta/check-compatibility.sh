#!/usr/bin/env bash
# Compare the portable and dispatched builds with untouched DRAGMAP 4f98e00.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BASE=4f98e00e2aedc85e27ea6c118cf7b16663036c14
JOBS=${JOBS:-2}
TMP=$(mktemp -d "${TMPDIR:-/tmp}/rdragmap-compat.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

extract_tree() {
  local revision=$1 destination=$2
  mkdir -p "$destination"
  git -C "$ROOT" archive "$revision" | tar -xf - -C "$destination"
}

run_logged() {
  local log=$1
  shift
  if ! "$@" >"$log" 2>&1; then
    tail -100 "$log" >&2
    return 1
  fi
}

extract_tree "$BASE" "$TMP/vanilla"
extract_tree HEAD "$TMP/portable"
extract_tree HEAD "$TMP/auto"

run_logged "$TMP/vanilla-build.log" \
  make -C "$TMP/vanilla" -j"$JOBS" OS=Linux HAS_GTEST=0 \
    CXX='g++ -include cstdint' \
    CXXWARNINGS='-Werror -Wno-unused-variable -Wno-free-nonheap-object -Wno-parentheses -Wno-error=nonnull' \
    CWARNINGS='-Werror -Wno-unused-variable -Wno-unused-function -Wno-format-truncation -Wno-error=format-overflow'
run_logged "$TMP/portable-build.log" \
  make -C "$TMP/portable" -j"$JOBS" OS=Linux HAS_GTEST=0 \
    DRAGMAP_HAVE_AVX2=0 VERSION_STRING=identity
run_logged "$TMP/auto-build.log" \
  make -C "$TMP/auto" -j"$JOBS" OS=Linux HAS_GTEST=0 VERSION_STRING=identity

mkdir -p "$TMP/ref21"
run_logged "$TMP/hash-build.log" \
  "$TMP/portable/build/release/dragen-os" \
    --build-hash-table true \
    --ht-reference "$TMP/portable/data/tiny/tiny-2x1Xrepeats.v8/tiny.fasta" \
    --output-directory "$TMP/ref21" \
    --ht-seed-len 21 --ht-size 16MB --ht-mem-limit 1GB \
    --ht-max-table-chunks 1 --ht-num-threads 1 --ht-write-hash-bin 1

grep -Eq '^hash_table_bytes[[:space:]]*=[[:space:]]*16777216$' "$TMP/ref21/hash_table.cfg"
grep -Eq '^pri_seed_bases[[:space:]]*=[[:space:]]*21$' "$TMP/ref21/hash_table.cfg"
grep -Eq '^ref_seed_interval[[:space:]]*=[[:space:]]*1$' "$TMP/ref21/hash_table.cfg"

mkdir -p "$TMP/run"
RUNNER="$TMP/run/dragen-os"
run_case() {
  local implementation=$1 case_name=$2
  shift 2
  cp "$TMP/$implementation/build/release/dragen-os" "$RUNNER"
  "$RUNNER" -r "$TMP/ref21" "$@" >"$TMP/$implementation-$case_name.sam" \
    2>"$TMP/$implementation-$case_name.log"
}

compare_case() {
  local case_name=$1
  shift
  for implementation in vanilla portable auto; do
    run_case "$implementation" "$case_name" "$@"
  done

  # Portable and runtime-dispatched builds must be completely byte-identical.
  cmp "$TMP/portable-$case_name.sam" "$TMP/auto-$case_name.sam"

  # Vanilla differs only at the two header lines corrected in ERRATA.md.
  grep -Ev '^@(PG|RG)[[:space:]]' "$TMP/vanilla-$case_name.sam" >"$TMP/vanilla-$case_name.allowed.sam"
  grep -Ev '^@(PG|RG)[[:space:]]' "$TMP/portable-$case_name.sam" >"$TMP/portable-$case_name.allowed.sam"
  cmp "$TMP/vanilla-$case_name.allowed.sam" "$TMP/portable-$case_name.allowed.sam"
  sha256sum "$TMP/portable-$case_name.allowed.sam"
}

COMMON=(--RGID rg --RGSM sample --preserve-map-align-order true --num-threads 1)
compare_case mismatch -1 "$TMP/portable/data/tiny/1read-1X.fastq" "${COMMON[@]}"
compare_case paired -1 "$TMP/portable/data/tiny/repeat-1X-interleaved.fastq" --interleaved \
  "${COMMON[@]}" \
  --Aligner.pe-stat-mean-insert 70 --Aligner.pe-stat-stddev-insert 10 \
  --Aligner.pe-stat-quartiles-insert '60 70 80' --Aligner.pe-stat-mean-read-len 66

if [[ -f "$TMP/auto/build/release/ssw_ssw/ssw_avx2.o" ]]; then
  objdump -d "$TMP/auto/build/release/ssw_ssw/ssw_avx2.o" |
    grep -Eq '\b(vzeroupper|ymm[0-9]+)\b'
fi
while IFS= read -r -d '' object; do
  if [[ $(basename "$object") != ssw_avx2.o ]] &&
    objdump -d "$object" | grep -Eq '\b(vzeroupper|ymm[0-9]+|zmm[0-9]+)\b'; then
    echo "unexpected AVX instruction in $object" >&2
    exit 1
  fi
done < <(find "$TMP/auto/build/release" -name '*.o' -print0)

echo "Compatibility check passed: dispatched=portable byte-for-byte; vanilla differs only at documented @PG/@RG lines."
