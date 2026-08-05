#' Explicit dragen-os child executable
#'
#' @param dragen_os Absolute path to `dragen-os`.
#' @export
RdragmapExecutables <- S7::new_class(
  "RdragmapExecutables",
  package = "Rdragmap",
  properties = list(dragen_os = .rdm_absolute_path)
)

.rdm_program_path <- function(directory, name) {
  suffixes <- if (identical(.Platform$OS.type, "windows")) {
    c(".exe", "")
  } else {
    c("", ".exe")
  }
  candidates <- file.path(directory, paste0(name, suffixes))
  existing <- candidates[file.exists(candidates) & !dir.exists(candidates)]
  if (length(existing)) existing[[1L]] else candidates[[1L]]
}

#' Resolve a packaged or explicitly supplied dragen-os executable
#'
#' This function never searches `PATH`. With no supplied path, it resolves only
#' the executable installed by this package. Supply one absolute directory or
#' one absolute executable path to use a separately built compatible program.
#'
#' @param directory Empty or one absolute executable directory.
#' @param dragen_os Empty or one absolute `dragen-os` path.
#' @return `RdragmapExecutables` or an `RdragmapInputErrorValue`.
#' @examples
#' native <- rdragmap_executables()
#' if (!rdragmap_is_error(native)) native@dragen_os
#' @export
rdragmap_executables <- function(directory = character(), dragen_os = character()) {
  .rdm_contract_call(
    code = "invalid_executable_request",
    details = list(api = "rdragmap_executables"),
    expression = {
      .rdm_validate_optional_path(directory, "directory")
      .rdm_validate_optional_path(dragen_os, "dragen_os")
      has_directory <- length(directory) == 1L
      has_executable <- length(dragen_os) == 1L
      if (has_directory && has_executable) {
        .rdm_signal_contract_violation(
          "supply directory or dragen_os, not both",
          code = "ambiguous_executable_source"
        )
      }

      if (!has_directory && !has_executable) {
        directory <- system.file("dragen", "bin", package = "Rdragmap")
        if (!nzchar(directory)) {
          return(rdragmap_error_value(
            message = "the installed package has no executable directory",
            kind = "input",
            code = "packaged_executable_directory_missing"
          ))
        }
        dragen_os <- .rdm_program_path(directory, "dragen-os")
      } else if (has_directory) {
        if (!dir.exists(directory)) {
          return(rdragmap_error_value(
            message = paste0("executable directory does not exist: ", directory),
            kind = "input",
            code = "executable_directory_missing",
            details = list(directory = directory)
          ))
        }
        dragen_os <- .rdm_program_path(directory, "dragen-os")
      }

      executable_ok <- .rdm_require_executable(dragen_os, "resolve_executables")
      if (rdragmap_is_error(executable_ok)) return(executable_ok)
      RdragmapExecutables(dragen_os = dragen_os)
    }
  )
}
