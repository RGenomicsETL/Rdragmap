rdragmap_source_files <- function(repo_root) {
  required_paths <- c(
    "COPYRIGHT",
    "Makefile",
    "config.mk",
    "make",
    "meta/check-pedantic.sh",
    "meta/pedantic-warnings.txt",
    "meta/probe-avx2.sh",
    "meta/probe-c-flags.sh",
    "meta/probe-cxx-flags.sh",
    "meta/vendor-simde.sh",
    "meta/patches",
    "src",
    "stubs",
    "thirdparty/dragen",
    "thirdparty/sswlib/ssw",
    "thirdparty/simde/COPYING",
    "thirdparty/simde/README.md",
    "thirdparty/simde/VERSION",
    "thirdparty/simde/simde"
  )
  missing <- required_paths[!file.exists(file.path(repo_root, required_paths))]
  if (length(missing)) {
    stop(
      "required native source paths are missing: ",
      paste(missing, collapse = ", ")
    )
  }

  directory_paths <- required_paths[dir.exists(file.path(repo_root, required_paths))]
  file_paths <- required_paths[!dir.exists(file.path(repo_root, required_paths))]
  directory_files <- unlist(lapply(directory_paths, function(path) {
    children <- list.files(
      file.path(repo_root, path),
      recursive = TRUE,
      full.names = FALSE,
      include.dirs = FALSE,
      all.files = TRUE,
      no.. = TRUE
    )
    file.path(path, children)
  }), use.names = FALSE)
  source_files <- sort(unique(c(file_paths, directory_files)))
  missing_files <- source_files[!file.exists(file.path(repo_root, source_files))]
  if (length(missing_files)) {
    stop(
      "native source closure changed while collecting files: ",
      paste(missing_files, collapse = ", ")
    )
  }
  source_files
}
