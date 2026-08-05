# Internal Rdragmap argument and path validation.

.rdm_scalar_string <- S7::new_property(
  class = S7::class_character,
  validator = function(value) {
    if (length(value) != 1L || is.na(value) || !nzchar(value)) {
      "must be one non-missing, non-empty string"
    }
  }
)

.rdm_absolute_path <- S7::new_property(
  class = S7::class_character,
  validator = function(value) {
    if (
      length(value) != 1L || is.na(value) || !nzchar(value) ||
        !.rdm_is_absolute_path(value) || .rdm_has_parent_traversal(value)
    ) {
      "must be one absolute path without parent traversal"
    }
  }
)

.rdm_id <- S7::new_property(
  class = S7::class_character,
  validator = function(value) {
    if (
      length(value) != 1L || is.na(value) ||
        !grepl("^[A-Za-z0-9][A-Za-z0-9._-]*$", value)
    ) {
      "must be one stable identifier"
    }
  }
)

.rdm_optional_id <- S7::new_property(
  class = S7::class_character,
  validator = function(value) {
    if (
      length(value) > 1L || anyNA(value) ||
        (length(value) == 1L &&
          !grepl("^[A-Za-z0-9][A-Za-z0-9._-]*$", value))
    ) {
      "must be empty or one stable identifier"
    }
  }
)

.rdm_nonnegative_integer <- S7::new_property(
  class = S7::class_integer,
  validator = function(value) {
    if (length(value) != 1L || is.na(value) || value < 0L) {
      "must be one non-negative integer"
    }
  }
)

.rdm_optional_integer <- S7::new_property(
  class = S7::class_integer,
  validator = function(value) {
    if (length(value) > 1L || anyNA(value)) {
      "must be empty or one non-missing integer"
    }
  }
)

.rdm_flag <- S7::new_property(
  class = S7::class_logical,
  validator = function(value) {
    if (length(value) != 1L || is.na(value)) {
      "must be TRUE or FALSE"
    }
  }
)

.rdm_is_absolute_path <- function(path) {
  grepl("^/", path) ||
    grepl("^[A-Za-z]:[/\\\\]", path) ||
    grepl("^\\\\\\\\", path)
}

.rdm_has_parent_traversal <- function(path) {
  any(strsplit(gsub("\\\\", "/", path), "/", fixed = TRUE)[[1L]] == "..")
}

.rdm_assert_scalar_character <- function(value, argument) {
  if (
    !is.character(value) || length(value) != 1L ||
      is.na(value) || !nzchar(value)
  ) {
    .rdm_signal_contract_violation(
      paste0(argument, " must be one non-missing, non-empty string"),
      code = "invalid_scalar_string",
      details = list(argument = argument)
    )
  }
  value
}

.rdm_assert_absolute_path <- function(path, argument) {
  path <- .rdm_assert_scalar_character(path, argument)
  if (!.rdm_is_absolute_path(path) || .rdm_has_parent_traversal(path)) {
    .rdm_signal_contract_violation(
      paste0(argument, " must be an absolute path without parent traversal"),
      code = "absolute_path_required",
      details = list(argument = argument, path = path)
    )
  }
  path
}

.rdm_validate_optional_path <- function(path, argument) {
  if (!is.character(path) || length(path) > 1L || anyNA(path)) {
    .rdm_signal_contract_violation(
      paste0(argument, " must be empty or one path"),
      code = "invalid_optional_path",
      details = list(argument = argument)
    )
  }
  if (length(path)) .rdm_assert_absolute_path(path, argument)
  invisible(path)
}

.rdm_assert_header_value <- function(value, argument) {
  value <- .rdm_assert_scalar_character(value, argument)
  if (grepl("[\r\n\t]", value)) {
    .rdm_signal_contract_violation(
      paste0(argument, " must not contain tabs or newlines"),
      code = "invalid_header_value",
      details = list(argument = argument)
    )
  }
  value
}

.rdm_assert_flag <- function(value, argument) {
  if (!is.logical(value) || length(value) != 1L || is.na(value)) {
    .rdm_signal_contract_violation(
      paste0(argument, " must be TRUE or FALSE"),
      code = "invalid_flag",
      details = list(argument = argument)
    )
  }
  value
}

.rdm_assert_integer <- function(value, argument, minimum = 0L, maximum = Inf) {
  valid <- is.numeric(value) && length(value) == 1L && !is.na(value) &&
    is.finite(value) && value == floor(value) &&
    value >= minimum && value <= maximum &&
    value >= -.Machine$integer.max && value <= .Machine$integer.max
  if (!valid) {
    .rdm_signal_contract_violation(
      paste0(argument, " must be an integer in [", minimum, ", ", maximum, "]"),
      code = "invalid_integer",
      details = list(argument = argument, minimum = minimum, maximum = maximum)
    )
  }
  as.integer(value)
}

.rdm_assert_number <- function(
  value,
  argument,
  minimum = -Inf,
  maximum = Inf,
  minimum_open = FALSE
) {
  valid <- is.numeric(value) && length(value) == 1L && !is.na(value) &&
    is.finite(value)
  if (valid) {
    valid <- if (minimum_open) value > minimum else value >= minimum
    valid <- valid && value <= maximum
  }
  if (!valid) {
    .rdm_signal_contract_violation(
      paste0(argument, " has an invalid numeric value"),
      code = "invalid_number",
      details = list(argument = argument, minimum = minimum, maximum = maximum)
    )
  }
  as.double(value)
}

.rdm_assert_size <- function(value, argument) {
  value <- .rdm_assert_scalar_character(value, argument)
  if (!grepl("^(?:0|[1-9][0-9]*)(?:\\.[0-9]+)?(?:B|KB|MB|GB)$", value)) {
    .rdm_signal_contract_violation(
      paste0(argument, " must be a non-negative size with B, KB, MB, or GB units"),
      code = "invalid_size",
      details = list(argument = argument, value = value)
    )
  }
  value
}

.rdm_require_input <- function(path, argument) {
  .rdm_assert_absolute_path(path, argument)
  if (!file.exists(path) || dir.exists(path)) {
    return(rdragmap_error_value(
      message = paste0(argument, " does not exist: ", path),
      kind = "input",
      code = "input_file_missing",
      details = list(argument = argument, path = path)
    ))
  }
  invisible(TRUE)
}

.rdm_require_output <- function(path, argument) {
  .rdm_assert_absolute_path(path, argument)
  if (file.exists(path)) {
    return(rdragmap_error_value(
      message = paste0(argument, " already exists: ", path),
      kind = "output",
      code = "output_exists",
      details = list(argument = argument, path = path)
    ))
  }
  parent <- dirname(path)
  if (!dir.exists(parent)) {
    return(rdragmap_error_value(
      message = paste0("output directory does not exist: ", parent),
      kind = "output",
      code = "output_directory_missing",
      details = list(argument = argument, path = path, directory = parent)
    ))
  }
  invisible(TRUE)
}

.rdm_require_new_directory <- function(path, argument) {
  .rdm_assert_absolute_path(path, argument)
  if (file.exists(path)) {
    return(rdragmap_error_value(
      message = paste0(argument, " already exists: ", path),
      kind = "output",
      code = "output_exists",
      details = list(argument = argument, path = path)
    ))
  }
  parent <- dirname(path)
  if (!dir.exists(parent)) {
    return(rdragmap_error_value(
      message = paste0("output directory does not exist: ", parent),
      kind = "output",
      code = "output_directory_missing",
      details = list(argument = argument, path = path, directory = parent)
    ))
  }
  invisible(TRUE)
}

.rdm_index_files <- c(
  config = "hash_table.cfg.bin",
  compressed_hash = "hash_table.cmp",
  reference = "reference.bin"
)

.rdm_index_missing_files <- function(directory) {
  names(.rdm_index_files)[
    !file.exists(file.path(directory, unname(.rdm_index_files))) |
      dir.exists(file.path(directory, unname(.rdm_index_files)))
  ]
}

.rdm_require_executable <- function(path, operation) {
  .rdm_assert_absolute_path(path, "executable")
  if (!file.exists(path) || dir.exists(path) || file.access(path, 1L) != 0L) {
    return(rdragmap_error_value(
      message = paste0("executable is unavailable: ", path),
      kind = "input",
      code = "executable_unavailable",
      details = list(path = path, operation = operation)
    ))
  }
  invisible(TRUE)
}

.rdm_assert_executables <- function(value) {
  if (rdragmap_is_error(value)) return(value)
  if (!isTRUE(tryCatch(
    S7::S7_inherits(value, RdragmapExecutables),
    error = function(condition) FALSE
  ))) {
    .rdm_signal_contract_violation(
      "executables must be an RdragmapExecutables object",
      code = "invalid_executables"
    )
  }
  value
}

.rdm_assert_index <- function(value) {
  if (rdragmap_is_error(value)) return(value)
  if (!isTRUE(tryCatch(
    S7::S7_inherits(value, RdragmapIndex),
    error = function(condition) FALSE
  ))) {
    .rdm_signal_contract_violation(
      "index must be an RdragmapIndex object",
      code = "invalid_index"
    )
  }
  value
}

.rdm_output_prefix <- function(output_sam) {
  if (!grepl("\\.sam$", output_sam, ignore.case = TRUE)) {
    .rdm_signal_contract_violation(
      "output_sam must end in .sam",
      code = "unsupported_alignment_output",
      details = list(path = output_sam)
    )
  }
  prefix <- sub("\\.sam$", "", basename(output_sam), ignore.case = TRUE)
  if (!nzchar(prefix)) {
    .rdm_signal_contract_violation(
      "output_sam must have a non-empty filename prefix",
      code = "invalid_output_prefix",
      details = list(path = output_sam)
    )
  }
  prefix
}
