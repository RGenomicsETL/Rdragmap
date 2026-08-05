# Validate a DRAGMAP v8 reference-index directory

The directory must contain `hash_table.cfg.bin`, `hash_table.cmp`, and
`reference.bin`. These are the files used by the packaged executable
when it loads its compressed reference index.

## Usage

``` r
rdragmap_index(directory)
```

## Arguments

- directory:

  Absolute reference-index directory.

## Value

`RdragmapIndex` or an `RdragmapInputErrorValue`.
