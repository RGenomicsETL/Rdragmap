# Build a DRAGMAP v8 reference index

Runs the package-owned `dragen-os` hash-table generator once. The output
directory must not already exist; its parent must exist. The returned
index contains the compressed hash table used by
[`rdragmap_align()`](https://rgenomicsetl.github.io/Rdragmap/reference/rdragmap_align.md).

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
  max_multi_base_seeds = integer()
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
#>  @ directory: chr "/tmp/RtmpUzmOO7/rdragmap-example-20965e3f682c/index"
unlink(work, recursive = TRUE, force = TRUE)
# }
```
