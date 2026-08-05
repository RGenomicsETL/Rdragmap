# AGENTS for Rdragmap

Rdragmap is a hard fork of `sounkou-bioinfo/DRAGMAP` that will carry an R
package wrapper and a portable native build. Preserve DRAGMAP behavior and
upstream attribution while making focused, executable changes.

## Current authorities

- The imported source history and `COPYRIGHT` own provenance and licensing.
- `config.mk` and `make/*.mk` own the native build.
- `thirdparty/simde/VERSION` and `meta/vendor-simde.sh` own the pinned SIMDe
  recipe. Never hand-edit `thirdparty/simde/simde`.
- Existing C++ tests and tiny end-to-end fixtures under `data/tiny` own mapping
  compatibility.

## Native rules

- Ordinary translation units must remain free of global x86 ISA flags.
- `common/Simd.hpp` is the one compatibility include for imported 128-bit and
  portable 256-bit intrinsic spelling.
- Native AVX2 code is compiled only as a separate object after compiler-target
  probing and is entered only after a runtime CPU and OS capability check.
- Keep allocator ownership, extents, and cleanup explicit. Do not abort an
  embedded R process from new library-facing code.
- Preserve upstream source notices and record vendored licenses in `COPYRIGHT`.

## Validation

Run focused checks first, then both native variants:

```sh
make clean && make HAS_GTEST=0 DRAGMAP_HAVE_AVX2=0
make clean && make HAS_GTEST=0
```

Compare portable and auto-dispatched output on the same tiny fixture when
changing mapping kernels. Finish with `git diff --check` and report checks not
run.

For the future R package, use tinytest, roxygen-generated `NAMESPACE` and
`man/`, tarball-based `R CMD check`, and the repository Makefile workflow.
Prose does not use em dashes.
