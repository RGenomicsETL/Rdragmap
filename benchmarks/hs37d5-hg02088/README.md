
<!-- Generated as README.md from README.Rmd. Edit README.Rmd and the benchmark CSV files. -->

# hs37d5 and HG02088 exome validation

This is an executed compatibility and performance check, not a bundled
data fixture. Large inputs and generated indexes remain outside Git.

## Authorities

Validation was run on 2026-08-05 with:

- untouched DRAGMAP commit `4f98e00e2aedc85e27ea6c118cf7b16663036c14`;
- Rdragmap commit `b7c5756561fcf5fe335d8e7a37dd5b3e3722c958`;
- 16 mapper or hash-builder threads;
- Ubuntu 24.04, Linux 6.8, 62 GiB RAM, and an Intel Core i5-13500 (20
  logical CPUs, AVX2 available).

The reference was the 1000 Genomes hs37d5 FASTA:

- URL:
  <https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/phase2_reference_assembly_sequence/hs37d5.fa.gz>
- compressed SHA-256:
  `e9157e19a95e01dfc47080b5b6aa559c861de90b9934c2ea7c49cd5ec49e0285`
- 86 sequences and 3,137,454,505 unpadded bases.

The read authority was the real 1000 Genomes phase 3 exome run SRR716421
from HG02088. The project sequence index classifies both mates as
`exome`:
<https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/20130502.phase3.sequence.index>.

- mate 1 URL:
  <https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/HG02088/sequence_read/SRR716421_1.filt.fastq.gz>
- mate 2 URL:
  <https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/HG02088/sequence_read/SRR716421_2.filt.fastq.gz>
- declared MD5: `bc97e5ddcd90f36bbe98324718b66a27` and
  `54e095386d935fc95e7ce25d32b3110d` (both verified);
- observed SHA-256:
  `baa696169f804ae46c468e9c69bb058fc41a753c17fdcdc23168ca8a3f186232` and
  `090ac1f91c97fb73441624aee8b5863afde1648c51939b3af608c11ef6321823`;
- 10,110,535 records in each mate, with gzip integrity verified.

## Hash-table compatibility

Both binaries built hs37d5 at the same canonical output path with:

``` sh
dragen-os \
  --build-hash-table true \
  --ht-reference hs37d5.fa \
  --output-directory INDEX \
  --ht-num-threads 16 \
  --ht-write-hash-bin 0
```

The following generated files were byte-identical:

- `hash_table.cmp` (`c835d1cf...10e45`);
- `reference.bin` (`0c23c0f8...37701`);
- `ref_index.bin` (`df020e03...edffa`);
- `repeat_mask.bin` (`1383eb3c...f12ba`);
- `str_table.bin` (`c077f618...8576`).

All text configuration fields after the generated command line were
identical, including:

``` text
digest               = 0xDA20A269
hash_digest          = 0xC7BA64EA
extend_table_digest  = 0x12663D7F
```

`hash_table.cfg.bin` differed only in its embedded generating command
string, because the executable paths have different lengths.
`hash_table_stats.txt` matched before its intentionally volatile
cycle-counter section. Untouched DRAGMAP successfully decompressed and
mapped against the Rdragmap-produced index.

A first full-reference run exposed that conventional complemented
CRC-32C is not the raw state transition used by the imported `crc32q`
hash digest. Commit `a5e8e9d` corrected that distinction; `b7c5756` uses
the exact fixed-size portable transition. A million chained random
64-bit transitions and fixed regression vectors match the x86 `crc32q`
oracle.

## Measured hash-build performance

| Build             | Wall time |  User CPU | System CPU | CPU utilization |       Peak RSS |
|:------------------|----------:|----------:|-----------:|----------------:|---------------:|
| untouched 4f98e00 |  418.60 s | 3514.02 s |   246.69 s |            898% | 60,671,092 KiB |
| Rdragmap b7c5756  |  461.11 s | 3499.04 s |   232.96 s |            809% | 61,902,868 KiB |

The Rdragmap run used 0.7% less aggregate CPU time but 10.2% more wall
time. Both runs exceeded physical-memory headroom and incurred millions
of major page faults, while CPU occupancy differed substantially. This
is evidence of CPU-work parity under a memory-constrained build, not
evidence of a 10.2% kernel regression; a larger-memory host and repeated
counterbalanced runs are required for a stable hash-build wall-time
claim.

## Mapping compatibility and performance

A 100,000-pair prefix was mapped by both binaries against the
Rdragmap-built index using 16 threads and
`--preserve-map-align-order true`. After removing only the documented
`@PG` and `@RG` header differences, all 200,146 SAM lines were
byte-identical with SHA-256
`50f9e6bce034f7d58e6952c8f16cc154f88e69caf23b85e82f67d1bc2a6a00af`.

| 100,000-pair run  | Wall time | User CPU | System CPU | CPU utilization |       Peak RSS |
|:------------------|----------:|---------:|-----------:|----------------:|---------------:|
| untouched 4f98e00 |   59.98 s | 910.16 s |    18.10 s |                 | 37,937,760 KiB |
| Rdragmap b7c5756  |   59.70 s | 912.12 s |    18.50 s |                 | 37,936,960 KiB |

The 0.28-second wall difference is 0.47% in Rdragmap’s favor and is
below what a single run can establish as a performance difference.

Both binaries then mapped all 10,110,535 pairs (20,221,070 reads). The
complete SAM streams were hashed without storing them; after removing
only `@PG` and `@RG`, both produced SHA-256
`2d84277058d45dd99861a39dbe55ad7c99be7477bce8c3a6cd9cbd3e5e735d60`. The
aligners reported 20,185,346 mapped reads (99.82%) and 20,190,926 total
alignments identically.

| Complete exome run | Wall time |  User CPU | System CPU | CPU utilization |       Peak RSS |
|:-------------------|----------:|----------:|-----------:|----------------:|---------------:|
| untouched 4f98e00  |  194.17 s | 2787.12 s |    20.77 s |           1446% | 37,936,960 KiB |
| Rdragmap b7c5756   |  193.35 s | 2746.79 s |    21.01 s |           1431% | 37,937,280 KiB |

Rdragmap was 0.82 seconds (0.42%) faster in this single complete run and
used 1.4% less aggregate CPU time. Treat this as measured parity rather
than a speedup claim. Hash decompression was also equivalent: 42.377
versus 42.650 seconds for the dominant auto-hit phase.

## Uncompressed memory-mapped index

A follow-up performance run on 2026-08-10 used the same Rdragmap
executable, index, inputs, thread count, and ordered-output setting. The
upstream `--ht-uncompress` operation materialized `hash_table.bin` and
`extend_table.bin` from the already validated compressed index, and
alignment used `--mmap-reference true`. The two additional files
occupied about 28 GiB and 3.2 GiB respectively; `hash_table.cmp`
occupied 4.0 GiB.

| Complete exome index path         | Wall time |  User CPU | System CPU | CPU utilization |       Peak RSS |
|:----------------------------------|----------:|----------:|-----------:|----------------:|---------------:|
| compressed, per-run decompression |  193.35 s | 2746.79 s |    21.01 s |           1431% | 37,937,280 KiB |
| uncompressed, memory-mapped       |  150.55 s | 1945.88 s |     3.88 s |           1295% | 35,753,248 KiB |

The mmap run reported the same 20,221,070 input reads and 20,190,926
total alignments. It sent SAM to `/dev/null`, so this is a performance
and record-count comparison rather than another full-output digest. On
this host and workload, mmap reduced wall time by 42.80 seconds (22.1%)
and aggregate CPU time by 818.04 seconds (29.6%). It incurred 5,209
major page faults and reported a 134.51 thousand-read/s mapping rate,
compared with 141.12 thousand reads/s for the compressed run after its
up-front decompression. The data therefore support avoiding repeated
decompression on this workload; they do not establish that page-faulted
mmap makes the mapping kernel itself faster.

The prefix results show the sensitivity of small-input timings to cache
state and the workflow’s 100,000-pair scheduling unit:

| 100,000-pair index path   | Wall time | User CPU | System CPU | CPU utilization |       Peak RSS |
|:--------------------------|----------:|---------:|-----------:|----------------:|---------------:|
| compressed                |   59.70 s | 912.12 s |    18.50 s |                 | 37,936,960 KiB |
| mmap, first run           |   36.15 s |  12.78 s |     8.17 s |             57% | 32,420,732 KiB |
| mmap, page-cache resident |   12.18 s |  10.83 s |     1.51 s |            101% | 32,511,732 KiB |

### Ten-million-pair CPU and threading audit

The 100,000-pair profile was dominated by fixed startup and was not used
for a threading conclusion. On 2026-08-11,
`perf record -F 99 -e cycles:u` instead sampled both index paths over
all **10,110,535 pairs** with 16 requested mapper threads. A
`/proc/PID/task/*/schedstat` sampler recorded each thread’s executing
and run-queue time every 0.5 seconds. Linux reports this hybrid CPU’s
efficiency-core and performance-core PMUs separately; percentages are
within a PMU and must not be added across PMUs.

| Index path | PMU      | Samples | Symbol                          | Overhead |
|:-----------|:---------|--------:|:--------------------------------|---------:|
| compressed | cpu_atom | 129,558 | ssw_align_avx2                  |   31.05% |
| compressed | cpu_atom | 129,558 | autoHitThread                   |   27.05% |
| compressed | cpu_atom | 129,558 | Hashtable::processInitialBucket |    5.96% |
| compressed | cpu_atom | 129,558 | banded_sw                       |    4.02% |
| compressed | cpu_atom | 129,558 | Seed::getPrimaryData            |    3.69% |
| compressed | cpu_core | 149,162 | autoHitThread                   |   33.03% |
| compressed | cpu_core | 149,162 | ssw_align_avx2                  |   20.83% |
| compressed | cpu_core | 149,162 | Hashtable::processInitialBucket |    6.47% |
| compressed | cpu_core | 149,162 | Seed::getPrimaryData            |    4.58% |
| compressed | cpu_core | 149,162 | banded_sw                       |    3.39% |
| mmap       | cpu_atom |  91,392 | ssw_align_avx2                  |   47.43% |
| mmap       | cpu_atom |  91,392 | Hashtable::processInitialBucket |    9.21% |
| mmap       | cpu_atom |  91,392 | banded_sw                       |    6.23% |
| mmap       | cpu_atom |  91,392 | Seed::getPrimaryData            |    5.84% |
| mmap       | cpu_atom |  91,392 | ssw_init_avx2                   |    3.59% |
| mmap       | cpu_core |  95,061 | ssw_align_avx2                  |   36.58% |
| mmap       | cpu_core |  95,061 | Hashtable::processInitialBucket |   11.25% |
| mmap       | cpu_core |  95,061 | Seed::getPrimaryData            |    7.76% |
| mmap       | cpu_core |  95,061 | banded_sw                       |    5.79% |
| mmap       | cpu_core |  95,061 | ssw_init_avx2                   |    3.88% |
| mmap       | cpu_core |  95,061 | inflate                         |    3.46% |

The complete compressed-path profile no longer resembles the
startup-only 100,000-pair result. `autoHitThread` accounted for 27.05%
and 33.03% of the two PMUs, while Smith-Waterman, hash lookup, seeding,
and alignment dominated the remaining run. With mmap removing hash
decompression, Smith-Waterman alone accounted for 47.43% and 36.58% and
hash-bucket processing for 9.21% and 11.25%.

The FASTQ gzip symbols were small even after mmap isolated the mapping
phase:

| PMU      | Symbol  | Overhead |
|:---------|:--------|---------:|
| cpu_atom | inflate |    1.45% |
| cpu_atom | crc32_z |    0.34% |
| cpu_core | inflate |    3.46% |
| cpu_core | crc32_z |    0.79% |

Within each mmap PMU, `inflate` plus `crc32_z` totalled 1.79% and 4.25%
of sampled cycles. Even eliminating those cycles completely gives
idealized Amdahl bounds of only 1.8% and 4.4%; making them four times
faster gives 1.4% and 3.3%. `FastqNRecordReader::read` was 0.52%/0.89%,
and `Tokenizer::reset` was 0.39%/0.42%. These are flat-profile cycle
shares, not promises of wall speedup, but they clearly reject gzip as
the dominant CPU cost on this workload.

The scheduler samples show the surrounding concurrency rather than only
where executing cycles landed:

| Index path | Phase      | Peak live threads | Elapsed sampled | Mean cores executing | Median cores executing | 95th percentile | Mean cores runnable |
|:-----------|:-----------|------------------:|----------------:|---------------------:|-----------------------:|----------------:|--------------------:|
| compressed | index_load |                21 |          59.9 s |                15.66 |                  18.95 |           19.77 |               0.668 |
| compressed | mapping    |                32 |         142.7 s |                13.01 |                  15.00 |           16.00 |               0.044 |
| mmap       | mapping    |                32 |         172.7 s |                10.87 |                  14.02 |           16.00 |               0.020 |

The source and runtime observations agree:

- compressed index loading uses `std::thread::hardware_concurrency()`
  rather than `--num-threads`; it reached 21 live threads including the
  main thread;
- mapping constructs a 32-thread pool so ordered blocks can park without
  preventing other work, but limits the outer executor to 16 mapper
  workers;
- the two gzip streams use independent but individually serial
  Boost/zlib filters, with a nested reader executor limited to two
  threads;
- input, insert-statistics feedback, alignment start, and output each
  retain an explicit block-order barrier at the inherited 100,000-pair
  scheduling unit;
- 16 threads accounted for more than 97% of sampled mmap cycles in each
  PMU; the other half of the pool was overwhelmingly parked;
- compressed mapping had a median 15.00 executing cores and a 16.00-core
  95th percentile. The mmap profile’s lower mean includes an initially
  cold mapped index with 157,417 major faults, plus pipeline ramp-up and
  drain, rather than evidence of FASTQ-reader saturation.

Therefore no rapidgzip or thread-broker integration is justified for
this pipeline now. Parallel gzip would have to take execution slots from
the alignment work that dominates the profile, while adding a
substantial native or Rust/FFI dependency and a new ordered-buffer
lifecycle. The current `rapidgzip` C++ design, `rapidgzip-rust`
`Read + Send` decoder, and `thread-broker` fixed-budget control law
remain useful references if a future production corpus shows material
inflater share or sustained mapper starvation; standalone decompressor
throughput is not sufficient evidence to reopen that decision.

The real run exposed one additional metrics-adapter defect unrelated to
SAM records: the internal `nextReference == -1` representation of
same-contig SAM `RNEXT =` was counted as a different chromosome. It
falsely labelled all 20,165,314 mapped paired reads as interchromosomal.
A focused regression now covers the corrected sentinel interpretation.
Re-running the 100,000-pair prefix after the fix reported 444 of 199,412
mapped paired reads (0.22%) on different chromosomes, including 215
(0.11%) at MAPQ 10 or greater.
