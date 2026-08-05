#!/usr/bin/env Rscript

main <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  script_arg <- grep("^--file=", args, value = TRUE)
  if (!length(script_arg)) stop("build-pkgdown.R must be run with Rscript")
  package_dir <- normalizePath(file.path(
    dirname(sub("^--file=", "", script_arg[[1L]])),
    ".."
  ))
  bin_dir <- file.path(package_dir, "inst", "dragen", "bin")
  cleanup <- function() {
    unlink(
      file.path(bin_dir, c("dragen-os", "dragen-os.exe")),
      force = TRUE
    )
    if (dir.exists(bin_dir) && !length(list.files(bin_dir, all.files = FALSE))) {
      unlink(bin_dir, recursive = TRUE, force = TRUE)
    }
    dragen_dir <- dirname(bin_dir)
    if (dir.exists(dragen_dir) && !length(list.files(dragen_dir, all.files = FALSE))) {
      unlink(dragen_dir, recursive = TRUE, force = TRUE)
    }
  }
  cleanup()
  on.exit(cleanup(), add = TRUE)
  old <- setwd(package_dir)
  on.exit(setwd(old), add = TRUE)
  pkgdown::build_site(new_process = FALSE)
}

main()
