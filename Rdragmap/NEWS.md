# Rdragmap 0.0.0.9000

- Probe GCC-only C tuning and warning flags separately from C++ tuning flags so
  Apple Clang can compile imported hash-generation sources under `-Werror`.

- Use the portable POSIX limits header for imported metrics compilation on
  macOS.

- Fix Apple Clang compilation for imported alignment extent and iterator
  initialization.

- Build against the R-universe macOS Boost bundle and use POSIX and Darwin
  facilities where the imported Linux implementation was not portable.

- Add a source-built R wrapper that owns and resolves `dragen-os` without
  searching `PATH`.
- Add typed S7 results, operational error values, and contract conditions for
  reference generation and FASTQ to SAM alignment.
- Add a reproducible native source archive, configure-time build, tinytest
  coverage, and tarball-based package Makefile workflow.
