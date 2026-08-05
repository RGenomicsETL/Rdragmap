#!/usr/bin/env Rscript

files <- c("README.Rmd", "CONFORMANCE.Rmd", "ERRATA.Rmd")
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(file_arg) != 1L) {
  stop("Unable to determine the render script path")
}
script <- normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
root <- dirname(dirname(script))

if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("The 'rmarkdown' package is required to render project documentation")
}

for (input in files) {
  rmarkdown::render(
    input = file.path(root, input),
    output_file = sub("[.]Rmd$", ".md", input),
    output_dir = root,
    envir = new.env(parent = globalenv()),
    quiet = TRUE
  )
}
