#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", args, value = TRUE)
if (!length(script_arg)) stop("check-source-archive.R must be run with Rscript")
package_dir <- normalizePath(file.path(dirname(sub("^--file=", "", script_arg[[1L]])), ".."))
repo_root <- normalizePath(file.path(package_dir, ".."))
archive <- file.path(package_dir, "tools", "dragmap-source.tar.xz")
if (!file.exists(archive)) stop("missing source archive: ", archive)
source(file.path(package_dir, "tools", "source-files.R"), local = TRUE)
expected <- rdragmap_source_files(repo_root)
listed <- utils::untar(archive, list = TRUE)
listed <- sub("/$", "", listed)
listed <- listed[nzchar(listed)]
if (any(grepl("^/|^\\.\\./|/\\.\\./", listed))) {
  stop("source archive has an unsafe member path")
}
if (!identical(sort(unique(listed)), expected)) {
  missing <- setdiff(expected, listed)
  unexpected <- setdiff(listed, expected)
  stop(
    "source archive closure mismatch",
    if (length(missing)) paste0("; missing: ", paste(missing, collapse = ", ")) else "",
    if (length(unexpected)) paste0("; unexpected: ", paste(unexpected, collapse = ", ")) else ""
  )
}
required <- c("COPYRIGHT", "Makefile", "config.mk", "src/dragen-os.cpp")
if (!all(required %in% listed)) {
  stop("source archive lacks executable build inputs")
}
cat("Validated ", archive, " with ", length(listed), " source files\n", sep = "")
