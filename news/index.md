# Changelog

## Rdragmap 0.0.0.9000

- Add `write_uncompressed` index generation and a validated end-to-end
  `mmap_reference` workflow, with an explicit disk-space tradeoff and a
  clear error when required uncompressed tables are absent.

- Unmap each memory-mapped index file using its validated extent,
  preventing a teardown crash exposed by the package’s small real mmap
  workflow.

- Create static archives with portable `ar` options accepted by GNU and
  Darwin toolchains.

- Use a pthread mutex-and-condition counter for the hash compressor on
  Darwin instead of deprecated unnamed POSIX semaphores.

- Stop forcing the POSIX limits header into every imported C source
  because its Darwin `NZERO` macro conflicts with the hash generator
  under `-Werror`.

- Probe GCC-only C tuning and warning flags separately from C++ tuning
  flags so Apple Clang can compile imported hash-generation sources
  under `-Werror`.

- Use the portable POSIX limits header for imported metrics compilation
  on macOS.

- Fix Apple Clang compilation for imported alignment extent and iterator
  initialization.

- Build against the R-universe macOS Boost bundle and use POSIX and
  Darwin facilities where the imported Linux implementation was not
  portable.

- Add a source-built R wrapper that owns and resolves `dragen-os`
  without searching `PATH`.

- Add typed S7 results, operational error values, and contract
  conditions for reference generation and FASTQ to SAM alignment.

- Add a reproducible native source archive, configure-time build,
  tinytest coverage, and tarball-based package Makefile workflow.
