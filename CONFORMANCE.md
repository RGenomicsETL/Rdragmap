
<!-- Generated as CONFORMANCE.md from CONFORMANCE.Rmd. Edit CONFORMANCE.Rmd. -->

# Rdragmap conformance record

This document records what has been executed, what has only been
compiled, and what remains unavailable. It is not a claim that every
imported exploratory test can run with every reference index.

## Authorities

- Upstream oracle: untouched DRAGMAP commit
  `4f98e00e2aedc85e27ea6c118cf7b16663036c14`.
- Portable implementation benchmarked at
  `b7c5756561fcf5fe335d8e7a37dd5b3e3722c958`.
- Same-contig metrics correction: `d1efbdc`.
- Consolidated evidence documentation: `146acbc`.
- Evidence date: 2026-08-05.

The imported source history and `COPYRIGHT` own provenance. `ERRATA.md`
owns intentional behavior corrections. Existing deterministic fixtures
and the untouched oracle own mapping compatibility.

## Status meanings

- **Passed**: the stated command or comparison executed successfully.
- **Compile-only**: all stated translation units compiled for the
  target, but no target-native process executed.
- **Fixture unavailable**: the imported program requires data not
  supplied by the repository and cannot be safely substituted with an
  arbitrary index.
- **Not attempted**: no evidence has been collected.

## Evidence matrix

| Capability                          | Status                       | Executed evidence                                                                                                                                                       |
|-------------------------------------|------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Imported provenance                 | Passed                       | Fork history retains `4f98e00` as the direct upstream base and preserves source notices.                                                                                |
| Portable x86 build                  | Passed                       | `make clean && make HAS_GTEST=0 DRAGMAP_HAVE_AVX2=0`.                                                                                                                   |
| Auto-dispatched x86 build           | Passed                       | Compiler probing built the staged AVX2 object and linked `dragen-os`.                                                                                                   |
| AVX2 isolation                      | Passed                       | Disassembly found AVX2 instructions only in `ssw_avx2.o`; ordinary objects receive no global x86 ISA flag.                                                              |
| Runtime AVX2 selection              | Passed on the benchmark host | Entry requires the runtime CPU and operating-system capability probe. Portable and dispatched tiny-fixture SAM records were byte-identical.                             |
| AArch64/NEON libraries              | Compile-only                 | 43 AArch64 objects in 11 archives compiled; no AVX2 object was present. QEMU and a native runner were unavailable.                                                      |
| Raw hash CRC semantics              | Passed                       | Fixed vectors and 1,000,000 chained random 64-bit transitions matched the imported x86 `crc32q` oracle.                                                                 |
| Tiny SAM differential               | Passed                       | Untouched and current outputs matched after normalizing only admitted `@PG` and `@RG` corrections.                                                                      |
| hs37d5 hash artifacts               | Passed                       | `hash_table.cmp`, `reference.bin`, `ref_index.bin`, `repeat_mask.bin`, and `str_table.bin` were byte-identical; table, hash, and extension digests matched.             |
| Cross-index consumption             | Passed                       | Untouched DRAGMAP decompressed and mapped with the Rdragmap-generated hs37d5 index.                                                                                     |
| Memory-mapped index                 | Passed                       | The package built and mapped a real tiny uncompressed index without the imported teardown crash; the full HG02088 mmap benchmark completed with matching record counts. |
| Real exome prefix                   | Passed                       | All normalized SAM bytes matched for 100,000 HG02088 pairs.                                                                                                             |
| Complete real exome                 | Passed                       | All 10,110,535 HG02088 pairs produced normalized SHA-256 `2d84277058d45dd99861a39dbe55ad7c99be7477bce8c3a6cd9cbd3e5e735d60` with both binaries.                         |
| Mapping-metrics corrections         | Passed                       | Five focused tests pass; a corrected 100,000-pair run reports 444 of 199,412 mapped paired reads on different chromosomes instead of the erroneous 100%.                |
| Imported self-contained GoogleTests | Passed                       | 21 unit/integration executables reached their `.passed` targets.                                                                                                        |
| Added self-contained GoogleTests    | Passed                       | `MappingStatsGtest` passes 5 tests and `RawCrcGtest` passes 1 test.                                                                                                     |
| ALT masking                         | Mechanism inspected          | `--ht-mask-bed` changes listed intervals to `N` before seeding. Accuracy improvement was not benchmarked.                                                               |
| ALT liftover                        | Unsupported                  | `altLiftover` is null, imported `liftover.c` is empty, and mapper handling has an unresolved TODO.                                                                      |
| Windows build                       | Not attempted                | Reserved for package portability work.                                                                                                                                  |
| Native AArch64 execution            | Not attempted                | Requires an AArch64 runner or QEMU.                                                                                                                                     |

Full human-input receipts, artifact digests, timing, and memory
measurements are in
[benchmarks/hs37d5-hg02088/README.md](benchmarks/hs37d5-hg02088/README.md).

## Native test groups

The repository contains three different kinds of GoogleTest programs:

1.  Unit tests under `src/lib/*/tests/unit`. Their `.passed` files are
    library prerequisites.
2.  Integration tests under `src/lib/*/tests/integration`. Their
    `.passed` files are also library prerequisites.
3.  Top-level programs under `tests/`. `MappingStatsGtest` and
    `RawCrcGtest` are self-contained regressions. `ExtendTableGtest`,
    `HashtableGtest`, and `MapperGtest` are imported exploratory
    programs tied to a particular external reference layout.

`make test` is the supported self-contained gate. It builds the native
libraries, thereby running groups 1 and 2, and then runs the two
self-contained programs from group 3.

## Why “Run all GoogleTests” was labelled failed

The background command named “Run all GoogleTests” enumerated every
executable whose name ended in `Gtest`. That name overstated what the
command could validly test because it also selected the three
external-reference exploratory programs.

The first selected exploratory program, `ExtendTableGtest`, requires
`REFDIR` or a reference-directory command argument. It is not a
self-contained test. The aggregate command therefore exited when that
required fixture was absent, after the ordinary unit and integration
programs had passed.

Two attempts established why the bundled tiny index is not a valid
substitute:

- `data/tiny` provides a zero-byte `extend_table.bin`, while the program
  unconditionally calls `mmap()` for a version 8 extension table;
- a newly generated small index had a non-empty extension table, but the
  program dereferences hard-coded offsets such as `0x1abb10ae` and
  `257097262`. `MapperGtest` similarly uses reference position
  `300000000`. Those coordinates exceed a small generated reference, and
  the exploratory program terminated with signal 11.

Thus `[bg failed] Run all GoogleTests` does **not** mean that all
GoogleTests failed. It means that an imprecise aggregate runner mixed
the self-contained tests with imported reference-specific programs that
had no compatible fixture. The 21 imported unit/integration executables
had passed, and the two added self-contained executables were
subsequently verified directly. No changed mapping-kernel assertion
failed. The external programs remain classified as **fixture
unavailable**, not passed.

## Differential acceptance rule

A native mapping change is accepted only when:

1.  a focused regression covers every deliberate correction;
2.  portable and auto-dispatched outputs agree;
3.  untouched and current deterministic SAM agree after only admitted
    normalization;
4.  `git diff --check` passes; and
5.  both portable and auto-dispatched native variants build.

Changes to mapping kernels additionally require repeating a real-input
comparison. New output differences must be added to `ERRATA.Rmd` before
they are accepted.

## R package handoff

The package wrapper must not weaken these claims. It should use the
installed package-owned executable and preserve process exit status,
diagnostics, and output paths. Package tests may use tiny fixtures, but
native mapping changes still require the differential checks above.
