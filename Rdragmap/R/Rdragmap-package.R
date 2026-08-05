#' Rdragmap
#'
#' A source-built R wrapper for the portable, history-preserving DRAGMAP fork.
#' It builds and invokes one package-owned `dragen-os` executable through an
#' explicit argument vector. It does not search `PATH` and does not expose the
#' native implementation archives as an R ABI.
#'
#' @keywords internal
#' @name Rdragmap-package
#' @rawNamespace import(S7)
#' @rawNamespace importFrom(processx, run)
"_PACKAGE"

.onLoad <- function(libname, pkgname) {
  S7::methods_register()
}
