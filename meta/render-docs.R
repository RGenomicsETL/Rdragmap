#!/usr/bin/env Rscript

files <- c(
  "README.Rmd",
  "CONFORMANCE.Rmd",
  "ERRATA.Rmd",
  file.path("benchmarks", "hs37d5-hg02088", "README.Rmd")
)
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
  input_path <- file.path(root, input)
  rmarkdown::render(
    input = input_path,
    output_file = sub("[.]Rmd$", ".md", basename(input_path)),
    output_dir = dirname(input_path),
    envir = new.env(parent = globalenv()),
    quiet = TRUE
  )
}
