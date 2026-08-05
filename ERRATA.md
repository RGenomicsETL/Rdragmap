# Rdragmap errata and compatibility contract

Rdragmap starts from `sounkou-bioinfo/DRAGMAP` commit
`4f98e00e2aedc85e27ea6c118cf7b16663036c14`. The default contract is identical
mapping behavior. A deliberate behavior correction is admitted only here and
must have an executable regression.

## Admitted corrections

### CPU instruction selection

Upstream adds `-msse4.2 -mavx2` to every translation unit. Binaries can fail
with `SIGILL` on CPUs without AVX2, as reported in Illumina issues 45 and 59,
and cannot compile for aarch64. Rdragmap compiles the ordinary implementation
through pinned SIMDe headers without global x86 ISA flags. The native AVX2 SSW
object is separate and is called only when a runtime CPU and operating-system
check succeeds.

On local aarch64 builds, upstream hash-generation branches leave CRC result
variables uninitialized and compile the x86 `rdtsc` instruction. Rdragmap uses
the existing portable CRC32C implementation on those targets and confines the
diagnostic cycle counter to x86. Hash-table CRC fields require the raw x86
`crc32q` state transition rather than conventional complemented CRC-32C;
`crc32c_raw()` applies that distinction explicitly. A fixed-vector regression
and full hs37d5 artifact comparison preserve the imported hash bytes and digest
fields.

### Explicit hash-table sizing

The imported generator destructively shifted the decoded `--ht-size` byte
count while deriving its address-bit representation, then reused the resulting
small mantissa for occupancy and memory calculations. For example, `16MB`
became `32`, which spuriously increased the seed interval and miscomputed
extension-table capacity. Rdragmap derives the encoding from a copy and retains
the requested byte count as the sizing authority. A tiny-reference regression
requires the requested 16 MiB table, seed length 21, and seed interval 1.

### Modern compiler safety findings

A histogram buffer allowed 20 decimal digits for a `uint64_t` but no terminating
null byte. It now uses bounded formatting into a larger buffer. A DMI probe
called `pclose(NULL)` after `popen()` failed and leaked its stream on a duplicate
field; both cleanup paths are now valid. These corrections do not affect
mapping records.

### SAM header conformance

Upstream writes `ID: DRAGEN-OS`, which contains an invalid space after `ID:`,
and writes the non-standard read-group platform `PL:PL0`. Rdragmap writes
`ID:DRAGMAP`, reports its actual build revision, and writes `PL:ILLUMINA`. This
corrects Illumina issues 46 and 50. Differential tests permit exactly these
header substitutions and require all remaining SAM bytes to match.

### Mapping metrics

The imported `ReadGroupAlignmentCounts` implementation had three independent
counter defects:

- `COUNT_ALL` ran only non-duplicate accounting because mutually exclusive
  branches tested its component bits in the wrong order;
- `reset()` left MAPQ bin zero unchanged;
- a reference-skip CIGAR operation incorrectly advanced over the following
  operation, undercounting splice, indel, clipping, and Q30 metrics and risking
  iterator overrun when the skip was last;
- the unknown edit distance `-1` from an unmapped read was added to an unsigned
  counter and reported as `18446744073709551615` mismatches.

Rdragmap tests these counters directly. DRAGMAP still does not perform duplicate
marking; duplicate metrics describe flags already present in input records.
These corrections affect the metrics stream, not alignment records.

### Self-contained fixed-width integer headers

The headers named in Illumina issue 63 now include `<cstdint>` directly instead
of relying on transitive includes. This changes compilation only.

## ALT-contig scope

The README's `--ht-mask-bed` path is implemented, not a no-op. During hash-table
generation, `MaskBedRegions()` changes only listed ALT intervals to `N` before
seeding. Unmasked, sufficiently divergent ALT sequence remains in the reference
and can absorb reads that would otherwise mismap, while strategically similar
segments do not compete with primary loci. This is the mask-based ALT strategy
described by the upstream authors in Illumina issue 3.

This checkout is **not liftover-ALT-aware**. `SetBuildHashTableOptions()` sets
`altLiftover` to null, the bundled `liftover.c` has no implementation, and the
mapper contains an unresolved `TODO` for extended liftover hits. Rdragmap must
not advertise ALT liftover or graph-reference behavior. Claims that the bundled
GRCh37/GRCh38 masks improve variant-calling accuracy require an independent
mapping and calling benchmark; source inspection proves the mechanism, not the
accuracy claim.

## Differential gate

The compatibility gate builds an untouched `4f98e00` tree and the current tree
with the same compiler, runs deterministic tiny-fixture mapping, normalizes only
the admitted SAM header corrections above, and requires byte identity. It also
requires the current portable and auto-dispatched binaries to produce identical
raw bytes. Any new difference requires a new section here and a focused
regression before it can be accepted.
