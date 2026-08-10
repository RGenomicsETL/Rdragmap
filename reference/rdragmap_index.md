# Validate a DRAGMAP v8 reference-index directory

The directory must contain `hash_table.cfg.bin`, `hash_table.cmp`, and
`reference.bin`. An index built with `write_uncompressed = TRUE` also
contains `hash_table.bin` and `extend_table.bin` for
`mmap_reference = TRUE` alignment.

## Usage

``` r
rdragmap_index(directory)
```

## Arguments

- directory:

  Absolute reference-index directory.

## Value

`RdragmapIndex` or an `RdragmapInputErrorValue`.
