# Build a DRAGMAP v8 reference index

Runs the package-owned `dragen-os` hash-table generator once. The output
directory must not already exist; its parent must exist. The returned
index always contains the compressed hash table. It can also retain the
much larger uncompressed hash and extension tables required for
memory-mapped alignment.

## Usage

``` r
rdragmap_build_index(
  reference_fasta,
  index_directory,
  executables = rdragmap_executables(),
  threads = 1L,
  hash_size = "0GB",
  memory_limit = "0GB",
  seed_length = 21L,
  seed_interval = 1,
  mask_bed = character(),
  decoys = character(),
  max_multi_base_seeds = integer(),
  write_uncompressed = FALSE
)
```

## Arguments

- reference_fasta:

  Absolute FASTA path.

- index_directory:

  Absolute, not-yet-existing output directory.

- executables:

  Explicit executable resolution from
  [`rdragmap_executables()`](https://rgenomicsetl.github.io/Rdragmap/reference/rdragmap_executables.md).

- threads:

  Positive hash-generation worker count.

- hash_size:

  Hash table size with `B`, `KB`, `MB`, or `GB` units. `"0GB"` requests
  the native automatic size calculation.

- memory_limit:

  Hash generation memory limit in the same units. `"0GB"` requests the
  native automatic limit.

- seed_length:

  Initial seed length.

- seed_interval:

  Reference positions per seed.

- mask_bed:

  Empty or one absolute BED path passed to `--ht-mask-bed`.

- decoys:

  Empty or one absolute FASTA path passed to `--ht-decoys`.

- max_multi_base_seeds:

  Empty or one non-negative maximum passed to
  `--ht-max-multi-base-seeds`.

- write_uncompressed:

  Whether to retain `hash_table.bin` and `extend_table.bin`. These files
  require substantially more disk space but permit
  `rdragmap_align(mmap_reference = TRUE)` without decompressing the hash
  table for every alignment process.

## Value

`RdragmapIndexBuildResult` or an `RdragmapErrorValue`.

## Examples

``` r
# \donttest{
work <- tempfile("rdragmap-example-")
dir.create(work)
built <- rdragmap_build_index(
  reference_fasta = system.file("extdata", "tiny.fasta", package = "Rdragmap"),
  index_directory = file.path(work, "index"),
  threads = 1L,
  hash_size = "16MB"
)
if (!rdragmap_is_error(built)) built@index
#> <Rdragmap::RdragmapIndex>
#>  @ directory: chr "/tmp/RtmpjLi2BG/rdragmap-example-200f3739f8d8/index"
unlink(work, recursive = TRUE, force = TRUE)
# }
```
