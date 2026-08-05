#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", args, value = TRUE)
if (!length(script_arg)) stop("bootstrap.R must be run with Rscript")
package_dir <- normalizePath(dirname(sub("^--file=", "", script_arg[[1L]])))
repo_root <- normalizePath(file.path(package_dir, ".."))
archive <- file.path(package_dir, "tools", "dragmap-source.tar.xz")
source(file.path(package_dir, "tools", "source-files.R"), local = TRUE)
source_files <- rdragmap_source_files(repo_root)

old <- setwd(repo_root)
on.exit(setwd(old), add = TRUE)
dir.create(dirname(archive), recursive = TRUE, showWarnings = FALSE)
if (file.exists(archive)) unlink(archive)
utils::tar(
  archive,
  files = source_files,
  compression = "xz",
  compression_level = 9L,
  tar = "internal"
)
if (!file.exists(archive) || file.info(archive)$size == 0) {
  stop("failed to create ", archive)
}
cat("Wrote ", archive, " (", file.info(archive)$size, " bytes)\n", sep = "")
