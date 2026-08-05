# A completed Rdragmap child-process operation

A completed Rdragmap child-process operation

A completed Rdragmap index build

A completed Rdragmap FASTQ alignment

## Usage

``` r
RdragmapRunResult(
  operation = character(0),
  outputs = list(),
  status = integer(0),
  stdout = character(0),
  stderr = character(0)
)

RdragmapIndexBuildResult(
  operation = character(0),
  outputs = list(),
  status = integer(0),
  stdout = character(0),
  stderr = character(0),
  index = RdragmapIndex()
)

RdragmapAlignmentResult(
  operation = character(0),
  outputs = list(),
  status = integer(0),
  stdout = character(0),
  stderr = character(0),
  index = RdragmapIndex(),
  paired = logical(0)
)
```

## Arguments

- operation:

  Stable operation identifier.

- outputs:

  Named output paths produced by the operation.

- status:

  Child-process exit status.

- stdout:

  Captured standard output.

- stderr:

  Captured standard error.

- index:

  The reference index used by the operation.

- paired:

  Whether the operation received paired FASTQ input.
