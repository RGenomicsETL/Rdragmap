
<!-- Generated as README.md from README.Rmd. Edit README.Rmd. -->

# Rdragmap

Rdragmap is a history-preserving hard fork of
[sounkou-bioinfo/DRAGMAP](https://github.com/sounkou-bioinfo/DRAGMAP),
starting from commit `4f98e00e2aedc85e27ea6c118cf7b16663036c14`. It
preserves imported DRAGMAP mapping behavior while making the native
build portable and suitable for a future R package wrapper.

The native command remains `dragen-os`. The R package interface is not
yet implemented.

## Current status

- Ordinary translation units use a portable C++17 and SIMDe baseline
  without global x86 ISA flags.
- Native AVX2 Smith-Waterman code is one separately compiled object
  entered only after a runtime CPU and operating-system capability
  check.
- Baseline x86 and auto-dispatched builds pass.
- The reusable native source set cross-compiles to AArch64/NEON. Native
  AArch64 execution has not yet been run.
- Hash artifacts and complete real-exome SAM output match untouched
  DRAGMAP, subject only to the documented SAM header corrections.

See [CONFORMANCE.md](CONFORMANCE.md) for the evidence matrix,
[ERRATA.md](ERRATA.md) for admitted corrections, and
[benchmarks/hs37d5-hg02088/README.md](benchmarks/hs37d5-hg02088/README.md)
for the executed human-reference benchmark.

## Build from source

### Requirements

- a C++17 compiler;
- GNU Make;
- zlib;
- Boost Iostreams and Program Options;
- GoogleTest when building tests.

A full human-reference hash build used about 62 GiB peak RSS in the
recorded hs37d5 run. Full-exome mapping used about 38 GiB peak RSS.

### Native builds

Build the portable baseline without AVX2:

``` sh
make clean
make HAS_GTEST=0 DRAGMAP_HAVE_AVX2=0
```

Build with compiler-probed AVX2 dispatch where supported:

``` sh
make clean
make HAS_GTEST=0
```

The executable is written to `build/release/dragen-os`. To install it
under `/usr/bin`:

``` sh
make install
```

Show the selected SIMD configuration with:

``` sh
make simd-info
```

### Tests and compatibility

Run the self-contained native test gate with:

``` sh
make test
```

This target runs imported unit and integration tests plus the focused
raw-CRC and mapping-metrics regressions. It intentionally excludes three
imported exploratory reference programs that require a specific
historical external index. Their status and the reason an earlier
aggregate GoogleTest job was labelled failed are recorded in
[CONFORMANCE.md](CONFORMANCE.md).

Run the deterministic untouched-upstream differential gate with:

``` sh
make compatibility-check
```

## Command-line use

Build a reference hash table:

``` sh
build/release/dragen-os \
  --build-hash-table true \
  --ht-reference reference.fasta \
  --output-directory reference-index
```

Align paired reads to SAM on standard output:

``` sh
build/release/dragen-os \
  -r reference-index \
  -1 reads_1.fastq.gz \
  -2 reads_2.fastq.gz \
  > result.sam
```

Align single-end reads:

``` sh
build/release/dragen-os \
  -r reference-index \
  -1 reads.fastq.gz \
  > result.sam
```

List all command-line options with:

``` sh
build/release/dragen-os --help
```

## ALT-contig scope

`--ht-mask-bed` masks listed reference intervals before hash seeding.
This is not complete ALT liftover support. The imported liftover
generator is absent and mapper liftover handling remains incomplete.
Rdragmap does not claim graph reference or full ALT-aware mapping
behavior.

## R package work

The planned package will own and discover its installed executable,
expose a small R API, use tinytest, and preserve this native
compatibility contract. Native correctness evidence is being recorded
before package implementation so wrapper failures can be distinguished
from mapper changes.

## Attribution and license

Imported history and notices remain authoritative. See
[COPYRIGHT](COPYRIGHT) and the source headers for upstream attribution
and licensing. Vendored SIMDe provenance and its license are also
recorded there.
