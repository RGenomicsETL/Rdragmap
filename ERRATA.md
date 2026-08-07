
<!-- Generated as ERRATA.md from ERRATA.Rmd. Edit ERRATA.Rmd. -->

# Rdragmap errata and compatibility contract

Rdragmap starts from `sounkou-bioinfo/DRAGMAP` commit
`4f98e00e2aedc85e27ea6c118cf7b16663036c14`. The default contract is
identical mapping behavior. A deliberate behavior correction is admitted
only here and must have an executable regression.

[CONFORMANCE.md](CONFORMANCE.md) records the execution status
separately. An item can be admitted here without implying that every
platform has executed it.

## Admitted corrections

### E-001: CPU instruction selection

Upstream adds `-msse4.2 -mavx2` to every translation unit. Binaries can
fail with `SIGILL` on CPUs without AVX2, as reported in Illumina issues
45 and 59, and cannot compile for AArch64. Rdragmap compiles the
ordinary implementation through pinned SIMDe headers without global x86
ISA flags. The native AVX2 SSW object is separate and is called only
when a runtime CPU and operating-system check succeeds.

On AArch64 builds, upstream hash-generation branches leave CRC result
variables uninitialized and compile the x86 `rdtsc` instruction.
Rdragmap uses the existing portable CRC32C implementation on those
targets and confines the diagnostic cycle counter to x86. Hash-table CRC
fields require the raw x86 `crc32q` state transition rather than
conventional complemented CRC-32C; `crc32c_raw()` applies that
distinction explicitly. `tests/RawCrcGtest.cpp`, a fixed-vector check,
and the full hs37d5 artifact comparison preserve imported hash bytes and
digest fields.

### E-002: Explicit hash-table sizing

The imported generator destructively shifted the decoded `--ht-size`
byte count while deriving its address-bit representation, then reused
the resulting small mantissa for occupancy and memory calculations. For
example, `16MB` became `32`, which spuriously increased the seed
interval and miscomputed extension-table capacity. Rdragmap derives the
encoding from a copy and retains the requested byte count as the sizing
authority. A tiny-reference regression requires the requested 16 MiB
table, seed length 21, and seed interval 1.

### E-003: Modern compiler safety findings

A histogram buffer allowed 20 decimal digits for a `uint64_t` but no
terminating null byte. It now uses bounded formatting into a larger
buffer. A DMI probe called `pclose(NULL)` after `popen()` failed and
leaked its stream on a duplicate field; both cleanup paths are now
valid. These corrections do not affect mapping records.

### E-004: SAM header conformance

Upstream writes `ID: DRAGEN-OS`, which contains an invalid space after
`ID:`, and writes the non-standard read-group platform `PL:PL0`.
Rdragmap writes `ID:DRAGMAP`, reports its actual build revision, and
writes `PL:ILLUMINA`. This corrects Illumina issues 46 and 50.
Differential tests permit exactly these header substitutions and require
all remaining SAM bytes to match.

### E-005: Mapping metrics

The imported `ReadGroupAlignmentCounts` implementation had five
independent counter defects:

- `COUNT_ALL` ran only non-duplicate accounting because mutually
  exclusive branches tested its component bits in the wrong order;
- `reset()` left MAPQ bin zero unchanged;
- a reference-skip CIGAR operation incorrectly advanced over the
  following operation, undercounting splice, indel, clipping, and Q30
  metrics and risking iterator overrun when the skip was last;
- the unknown edit distance `-1` from an unmapped read was added to an
  unsigned counter and reported as `18446744073709551615` mismatches;
- same-contig pairs use the internal `nextReference == -1` sentinel that
  emits SAM `RNEXT` as `=`, but the metrics adapter interpreted the
  sentinel as a different chromosome. On the executed HG02088 exome this
  falsely reported every one of 20,165,314 mapped paired reads as
  interchromosomal.

`tests/MappingStatsGtest.cpp` tests these counters directly. After the
sentinel fix, the 100,000-pair HG02088 prefix reported 444 of 199,412
mapped paired reads on different chromosomes, including 215 at MAPQ 10
or greater. DRAGMAP still does not perform duplicate marking; duplicate
metrics describe flags already present in input records. These
corrections affect the metrics stream, not alignment records.

### E-006: Self-contained fixed-width integer headers

The headers named in Illumina issue 63 now include `<cstdint>` directly
instead of relying on transitive includes. This changes compilation
only.

### E-007: Hash-generator host-version prototype

The imported generator calls `getHostVersion(0)` although its declared
and implemented C signature has no parameter. Modern C compilers reject
that call. Rdragmap calls `getHostVersion()` with the matching
signature. This changes compilation only. The package source-tarball
installation and both clean native build variants compile the generator
as the regression check.

### E-008: Debug macro header dependency

`common/Debug.hpp` uses `BOOST_CURRENT_FUNCTION` but did not include
`<boost/current_function.hpp>`, its defining header. Imported include
ordering usually masked that dependency, but a package build can include
it before a Boost exception header and then fails to compile. Rdragmap
includes the defining header directly. This changes compilation only.
`check-debug-header` compiles that header before every other project
header, and package configuration invokes it with the native executable
build. The source-tarball package check and clean native builds are the
regression checks.

### E-009: Iterator-range header dependencies

`Mapper.cpp` and `SamGenerator.hpp` use `boost::make_iterator_range()`
without including `<boost/range/iterator_range.hpp>`, its defining
header. Older Boost include ordering masked the omission, but the
r-universe build with Boost 1.90 rejected `Mapper.cpp`. Rdragmap
includes the defining header at each use site. This changes compilation
only. The source-tarball package check and clean native builds compile
the mapper and SAM generator as the regression checks.

### E-010: Hash-config const-correctness

The hash-config parser stored read-only `strstr()` results in mutable
pointers. Modern C compilers reject the discarded qualifiers.
`processComment()` now keeps those search results const.
`regenHashTableError()` previously also wrote a null terminator through
its `const char*` input to remove `.bin`; it now copies the prefix into
a bounded local path before reading the text config. This preserves the
regeneration message without modifying the caller’s path. The
source-tarball package check and clean native builds compile the
hash-config parser as the regression checks.

### E-011: Run-statistics fixed-width integers

The `RunStats` stub uses `uint32_t` and `uint64_t` but did not include
`<cstdint>`. A package build with a different standard-library include
order therefore failed. The stub now includes the defining standard
header directly. This changes compilation only. `check-stub-header`
compiles that header before all other project headers during native and
package-owned builds.

### E-012: Compiler-probed tuning flags

The imported release build applies GCC-specific optimization flags to
every C++ compiler. Apple Clang rejects several of these under
`-Werror`, preventing package installation. Rdragmap probes each
imported tuning flag with the selected compiler and uses only accepted
flags, retaining `-O2` and the accepted GCC flags. This changes
optimization selection only. The local Clang portable build and its
native CI lane compile the regression path.

### E-013: Clang C and C++ conformance

The imported source also relied on GCC-only atomic builtin spellings,
diagnostic names, explicit constructor-instantiation syntax,
variable-length C++ arrays, and unused implementation details accepted
by GCC. Rdragmap uses the portable `__atomic_exchange_n` builtin with
the same sequentially consistent order, unsigned byte constants,
vector-backed temporary BAM buffers, standard template instantiation
syntax, and explicit `[[maybe_unused]]` annotations. Local-build only
hash-generation logging counters are no longer calculated. These changes
preserve byte values and mapping logic while making the C and C++
sources accepted by Clang. The local Clang portable build and native CI
lane compile the regression path.

## ALT-contig limitation

The README’s `--ht-mask-bed` path is implemented, not a no-op. During
hash-table generation, `MaskBedRegions()` changes only listed ALT
intervals to `N` before seeding. Unmasked, sufficiently divergent ALT
sequence remains in the reference and can absorb reads that would
otherwise mismap, while strategically similar segments do not compete
with primary loci. This is the mask-based ALT strategy described by the
upstream authors in Illumina issue 3.

This checkout is **not liftover-ALT-aware**.
`SetBuildHashTableOptions()` sets `altLiftover` to null, the bundled
`liftover.c` has no implementation, and the mapper contains an
unresolved TODO for extended liftover hits. Rdragmap must not advertise
ALT liftover or graph-reference behavior. Claims that bundled GRCh37 or
GRCh38 masks improve variant-calling accuracy require an independent
mapping and calling benchmark; source inspection proves the mechanism,
not the accuracy claim.

## Test-fixture limitation

The top-level imported `ExtendTableGtest`, `HashtableGtest`, and
`MapperGtest` are exploratory programs tied to a particular external
reference index and hard-coded human-reference coordinates. They are not
admitted behavior corrections and are not part of `make test`. Their
current status is documented in [CONFORMANCE.md](CONFORMANCE.md) rather
than being hidden as a passing test.

## Differential gate

The compatibility gate builds an untouched `4f98e00` tree and the
current tree with the same compiler, runs deterministic tiny-fixture
mapping, normalizes only the admitted SAM header corrections above, and
requires byte identity. It also requires the current portable and
auto-dispatched binaries to produce identical raw bytes. Any new
difference requires a new numbered section here and a focused regression
before it can be accepted.
