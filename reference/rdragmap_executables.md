# Resolve a packaged or explicitly supplied dragen-os executable

This function never searches `PATH`. With no supplied path, it resolves
only the executable installed by this package. Supply one absolute
directory or one absolute executable path to use a separately built
compatible program.

## Usage

``` r
rdragmap_executables(directory = character(), dragen_os = character())
```

## Arguments

- directory:

  Empty or one absolute executable directory.

- dragen_os:

  Empty or one absolute `dragen-os` path.

## Value

`RdragmapExecutables` or an `RdragmapInputErrorValue`.

## Examples

``` r
native <- rdragmap_executables()
if (!rdragmap_is_error(native)) native@dragen_os
#> [1] "/tmp/Rtmpvcihrc/temp_libpath207e73c41891/Rdragmap/dragen/bin/dragen-os"
```
