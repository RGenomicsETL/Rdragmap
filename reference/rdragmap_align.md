# Align FASTQ reads with a DRAGMAP v8 reference index

Runs the package-owned `dragen-os` executable once and writes SAM plus
native mapping metrics beside `output_sam`. Paired input also writes
native insert-size statistics. The wrapper preserves map/align order by
default so that the native SAM ordering remains deterministic.

## Usage

``` r
rdragmap_align(
  index,
  read1,
  output_sam,
  read2 = character(),
  executables = rdragmap_executables(),
  read_group_id = "1",
  sample_name = "none",
  threads = 1L,
  fastq_offset = 33L,
  enable_sampling = TRUE,
  preserve_order = TRUE,
  mmap_reference = FALSE
)
```

## Arguments

- index:

  A validated `RdragmapIndex`.

- read1:

  Absolute first FASTQ path, optionally gzip-compressed.

- output_sam:

  Absolute, not-yet-existing `.sam` output path.

- read2:

  Empty or one absolute mate FASTQ path.

- executables:

  Explicit executable resolution from
  [`rdragmap_executables()`](https://rgenomicsetl.github.io/Rdragmap/reference/rdragmap_executables.md).

- read_group_id:

  Read-group identifier recorded in the SAM header.

- sample_name:

  Read-group sample recorded in the SAM header.

- threads:

  Positive mapper/aligner worker count.

- fastq_offset:

  FASTQ quality offset, `33L` or `64L`.

- enable_sampling:

  Whether the native program estimates paired-end insert-size parameters
  from the input.

- preserve_order:

  Whether to preserve deterministic map/align order.

- mmap_reference:

  Whether to memory-map the decompressed reference.

## Value

`RdragmapAlignmentResult` or an `RdragmapErrorValue`.

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
if (!rdragmap_is_error(built)) {
  aligned <- rdragmap_align(
    index = built@index,
    read1 = system.file("extdata", "one.fastq", package = "Rdragmap"),
    output_sam = file.path(work, "example.sam"),
    read_group_id = "tiny",
    sample_name = "tiny",
    threads = 1L,
    enable_sampling = FALSE
  )
  if (!rdragmap_is_error(aligned)) aligned@outputs
}
#> $sam
#> [1] "/tmp/RtmpUzmOO7/rdragmap-example-20966faee10a/example.sam"
#> 
#> $mapping_metrics
#> [1] "/tmp/RtmpUzmOO7/rdragmap-example-20966faee10a/example.mapping_metrics.csv"
#> 
unlink(work, recursive = TRUE, force = TRUE)
# }
```
