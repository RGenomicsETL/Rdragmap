#' An Rdragmap reference index
#'
#' A reference index produced by `rdragmap_build_index()` or validated by
#' `rdragmap_index()`. It records an absolute directory containing the native
#' DRAGMAP v8 reference, compressed hash table, and binary configuration. An
#' index may additionally retain uncompressed tables for memory-mapped alignment.
#'
#' @param directory Absolute reference-index directory.
#' @export
RdragmapIndex <- S7::new_class(
  "RdragmapIndex",
  package = "Rdragmap",
  properties = list(directory = .rdm_absolute_path),
  validator = function(self) {
    missing <- .rdm_index_missing_files(self@directory)
    if (length(missing)) {
      paste0(
        "@directory lacks required index files: ",
        paste(unname(.rdm_index_files[missing]), collapse = ", ")
      )
    }
  }
)

#' A typed Rdragmap operational error value
#'
#' Invalid API calls signal `rdragmap_contract_violation()` conditions. Expected
#' unavailable inputs, occupied outputs, unavailable executables, and native
#' child-process failures are returned as values.
#'
#' @param message Human-readable description.
#' @param code Stable machine-readable code.
#' @param details Structured error details.
#' @param source Optional source condition or backend value.
#' @param operation Empty or one stable child-process operation identifier.
#' @param status Empty or one child-process exit status.
#' @export
RdragmapErrorValue <- S7::new_class(
  "RdragmapErrorValue",
  package = "Rdragmap",
  abstract = TRUE,
  properties = list(
    message = .rdm_scalar_string,
    code = .rdm_id,
    details = S7::class_list,
    source = S7::class_any,
    operation = .rdm_optional_id,
    status = .rdm_optional_integer
  )
)

#' @rdname RdragmapErrorValue
#' @export
RdragmapInputErrorValue <- S7::new_class(
  "RdragmapInputErrorValue",
  package = "Rdragmap",
  parent = RdragmapErrorValue
)

#' @rdname RdragmapErrorValue
#' @export
RdragmapOutputErrorValue <- S7::new_class(
  "RdragmapOutputErrorValue",
  package = "Rdragmap",
  parent = RdragmapErrorValue
)

#' @rdname RdragmapErrorValue
#' @export
RdragmapProcessErrorValue <- S7::new_class(
  "RdragmapProcessErrorValue",
  package = "Rdragmap",
  parent = RdragmapErrorValue
)

#' Construct a typed Rdragmap operational error
#'
#' @inheritParams RdragmapErrorValue
#' @param kind Operational error category.
#' @return An `RdragmapErrorValue` subclass.
#' @export
rdragmap_error_value <- function(
  message,
  kind = c("input", "output", "process"),
  code,
  details = list(),
  source = NULL,
  operation = character(),
  status = integer()
) {
  .rdm_contract_call(
    code = "invalid_error_value",
    details = list(api = "rdragmap_error_value"),
    expression = {
      kind <- match.arg(kind)
      common <- list(
        message = message,
        code = code,
        details = details,
        source = source,
        operation = character(),
        status = integer()
      )
      switch(kind,
        input = do.call(RdragmapInputErrorValue, common),
        output = do.call(RdragmapOutputErrorValue, common),
        process = {
          operation <- .rdm_assert_scalar_character(operation, "operation")
          if (length(status)) {
            status <- .rdm_assert_integer(
              status,
              "status",
              minimum = -.Machine$integer.max,
              maximum = .Machine$integer.max
            )
          }
          common$operation <- operation
          common$status <- status
          do.call(RdragmapProcessErrorValue, common)
        }
      )
    }
  )
}

#' Test whether a value is an Rdragmap operational error
#'
#' @param value Any R value.
#' @return A logical scalar.
#' @export
rdragmap_is_error <- function(value) {
  isTRUE(tryCatch(
    S7::S7_inherits(value, RdragmapErrorValue),
    error = function(condition) FALSE
  ))
}

#' Construct a typed Rdragmap contract condition
#'
#' @param message Human-readable description.
#' @param call Call associated with the violation.
#' @param code Stable machine-readable code.
#' @param details Structured condition details.
#' @return An `rdragmap_contract_violation` condition.
#' @export
rdragmap_contract_violation <- function(
  message,
  call = NULL,
  code = "invalid_contract",
  details = list()
) {
  invalid <- if (
    !is.character(message) || length(message) != 1L ||
      is.na(message) || !nzchar(message)
  ) {
    "message"
  } else if (!is.null(call) && !is.call(call)) {
    "call"
  } else if (
    !is.character(code) || length(code) != 1L || is.na(code) ||
      !grepl("^[A-Za-z0-9][A-Za-z0-9._-]*$", code)
  ) {
    "code"
  } else if (!is.list(details)) {
    "details"
  } else {
    character()
  }
  if (length(invalid)) {
    base::stop(structure(
      list(
        message = paste0(invalid, " has an invalid type or shape"),
        call = sys.call(),
        code = "invalid_contract_condition",
        details = list(argument = invalid)
      ),
      class = c("rdragmap_contract_violation", "error", "condition")
    ))
  }
  structure(
    list(message = message, call = call, code = code, details = details),
    class = c("rdragmap_contract_violation", "error", "condition")
  )
}

.rdm_signal_contract_violation <- function(
  message,
  call = sys.call(-1L),
  code = "invalid_contract",
  details = list()
) {
  base::stop(rdragmap_contract_violation(message, call, code, details))
}

.rdm_contract_call <- function(code, details, expression) {
  caller_call <- sys.call(-1L)
  tryCatch(
    force(expression),
    error = function(condition) {
      if (inherits(condition, "rdragmap_contract_violation")) {
        base::stop(condition)
      }
      .rdm_signal_contract_violation(
        message = conditionMessage(condition),
        call = caller_call,
        code = code,
        details = c(details, list(source_class = class(condition)))
      )
    }
  )
}

#' A completed Rdragmap child-process operation
#'
#' @param operation Stable operation identifier.
#' @param outputs Named output paths produced by the operation.
#' @param status Child-process exit status.
#' @param stdout Captured standard output.
#' @param stderr Captured standard error.
#' @export
RdragmapRunResult <- S7::new_class(
  "RdragmapRunResult",
  package = "Rdragmap",
  properties = list(
    operation = .rdm_id,
    outputs = S7::class_list,
    status = .rdm_nonnegative_integer,
    stdout = S7::class_character,
    stderr = S7::class_character
  )
)

#' A completed Rdragmap index build
#'
#' @rdname RdragmapRunResult
#' @param index The validated index produced by the operation.
#' @export
RdragmapIndexBuildResult <- S7::new_class(
  "RdragmapIndexBuildResult",
  package = "Rdragmap",
  parent = RdragmapRunResult,
  properties = list(index = RdragmapIndex)
)

#' A completed Rdragmap FASTQ alignment
#'
#' @rdname RdragmapRunResult
#' @param index The reference index used by the operation.
#' @param paired Whether the operation received paired FASTQ input.
#' @export
RdragmapAlignmentResult <- S7::new_class(
  "RdragmapAlignmentResult",
  package = "Rdragmap",
  parent = RdragmapRunResult,
  properties = list(
    index = RdragmapIndex,
    paired = .rdm_flag
  )
)
