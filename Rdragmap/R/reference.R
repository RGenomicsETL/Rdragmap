#' Validate a DRAGMAP v8 reference-index directory
#'
#' The directory must contain `hash_table.cfg.bin`, `hash_table.cmp`, and
#' `reference.bin`. These are the files used by the packaged executable when it
#' loads its compressed reference index.
#'
#' @param directory Absolute reference-index directory.
#' @return `RdragmapIndex` or an `RdragmapInputErrorValue`.
#' @export
rdragmap_index <- function(directory) {
  .rdm_contract_call(
    code = "invalid_index_request",
    details = list(api = "rdragmap_index"),
    expression = {
      directory <- .rdm_assert_absolute_path(directory, "directory")
      if (!dir.exists(directory)) {
        return(rdragmap_error_value(
          message = paste0("reference-index directory does not exist: ", directory),
          kind = "input",
          code = "index_directory_missing",
          details = list(directory = directory)
        ))
      }
      missing <- .rdm_index_missing_files(directory)
      if (length(missing)) {
        return(rdragmap_error_value(
          message = paste0(
            "reference-index directory lacks required files: ",
            paste(unname(.rdm_index_files[missing]), collapse = ", ")
          ),
          kind = "input",
          code = "index_files_missing",
          details = list(
            directory = directory,
            missing = unname(.rdm_index_files[missing])
          )
        ))
      }
      RdragmapIndex(directory = directory)
    }
  )
}

#' Build a DRAGMAP v8 reference index
#'
#' Runs the package-owned `dragen-os` hash-table generator once. The output
#' directory must not already exist; its parent must exist. The returned index
#' contains the compressed hash table used by `rdragmap_align()`.
#'
#' @param reference_fasta Absolute FASTA path.
#' @param index_directory Absolute, not-yet-existing output directory.
#' @param executables Explicit executable resolution from
#'   `rdragmap_executables()`.
#' @param threads Positive hash-generation worker count.
#' @param hash_size Hash table size with `B`, `KB`, `MB`, or `GB` units. `"0GB"`
#'   requests the native automatic size calculation.
#' @param memory_limit Hash generation memory limit in the same units. `"0GB"`
#'   requests the native automatic limit.
#' @param seed_length Initial seed length.
#' @param seed_interval Reference positions per seed.
#' @param mask_bed Empty or one absolute BED path passed to `--ht-mask-bed`.
#' @param decoys Empty or one absolute FASTA path passed to `--ht-decoys`.
#' @param max_multi_base_seeds Empty or one non-negative maximum passed to
#'   `--ht-max-multi-base-seeds`.
#' @return `RdragmapIndexBuildResult` or an `RdragmapErrorValue`.
#' @examples
#' \donttest{
#' work <- tempfile("rdragmap-example-")
#' dir.create(work)
#' built <- rdragmap_build_index(
#'   reference_fasta = system.file("extdata", "tiny.fasta", package = "Rdragmap"),
#'   index_directory = file.path(work, "index"),
#'   threads = 1L,
#'   hash_size = "16MB"
#' )
#' if (!rdragmap_is_error(built)) built@index
#' unlink(work, recursive = TRUE, force = TRUE)
#' }
#' @export
rdragmap_build_index <- function(
  reference_fasta,
  index_directory,
  executables = rdragmap_executables(),
  threads = 1L,
  hash_size = "0GB",
  memory_limit = "0GB",
  seed_length = 21L,
  seed_interval = 1,
  mask_bed = character(),
  decoys = character(),
  max_multi_base_seeds = integer()
) {
  .rdm_contract_call(
    code = "invalid_index_build_request",
    details = list(api = "rdragmap_build_index"),
    expression = {
      reference_fasta <- .rdm_assert_absolute_path(reference_fasta, "reference_fasta")
      index_directory <- .rdm_assert_absolute_path(index_directory, "index_directory")
      executables <- .rdm_assert_executables(executables)
      if (rdragmap_is_error(executables)) return(executables)
      .rdm_validate_optional_path(mask_bed, "mask_bed")
      .rdm_validate_optional_path(decoys, "decoys")
      threads <- .rdm_assert_integer(threads, "threads", 1L, .Machine$integer.max)
      hash_size <- .rdm_assert_size(hash_size, "hash_size")
      memory_limit <- .rdm_assert_size(memory_limit, "memory_limit")
      seed_length <- .rdm_assert_integer(
        seed_length,
        "seed_length",
        1L,
        .Machine$integer.max
      )
      seed_interval <- .rdm_assert_number(
        seed_interval,
        "seed_interval",
        0,
        minimum_open = TRUE
      )
      if (
        !is.numeric(max_multi_base_seeds) ||
          length(max_multi_base_seeds) > 1L || anyNA(max_multi_base_seeds)
      ) {
        .rdm_signal_contract_violation(
          "max_multi_base_seeds must be empty or one non-negative integer",
          code = "invalid_max_multi_base_seeds"
        )
      }
      if (length(max_multi_base_seeds)) {
        max_multi_base_seeds <- .rdm_assert_integer(
          max_multi_base_seeds,
          "max_multi_base_seeds",
          0L,
          .Machine$integer.max
        )
      }

      inputs <- c(
        list(reference_fasta = reference_fasta),
        if (length(mask_bed)) list(mask_bed = mask_bed),
        if (length(decoys)) list(decoys = decoys)
      )
      executable_ok <- .rdm_require_executable(
        executables@dragen_os,
        "build_index"
      )
      if (rdragmap_is_error(executable_ok)) return(executable_ok)
      inputs_ok <- lapply(names(inputs), function(name) {
        .rdm_require_input(inputs[[name]], name)
      })
      input_error <- Filter(rdragmap_is_error, inputs_ok)
      if (length(input_error)) return(input_error[[1L]])
      directory_ok <- .rdm_require_new_directory(index_directory, "index_directory")
      if (rdragmap_is_error(directory_ok)) return(directory_ok)

      if (!dir.create(index_directory, recursive = FALSE, showWarnings = FALSE)) {
        return(rdragmap_error_value(
          message = paste0("failed to create index_directory: ", index_directory),
          kind = "output",
          code = "index_directory_create_failed",
          details = list(index_directory = index_directory)
        ))
      }
      completed <- FALSE
      on.exit(
        if (!completed) unlink(index_directory, recursive = TRUE, force = TRUE),
        add = TRUE
      )

      outputs <- list(
        config_text = file.path(index_directory, "hash_table.cfg"),
        config = file.path(index_directory, "hash_table.cfg.bin"),
        compressed_hash = file.path(index_directory, "hash_table.cmp"),
        statistics = file.path(index_directory, "hash_table_stats.txt"),
        reference = file.path(index_directory, "reference.bin"),
        reference_index = file.path(index_directory, "ref_index.bin"),
        repeat_mask = file.path(index_directory, "repeat_mask.bin"),
        strings = file.path(index_directory, "str_table.bin")
      )
      arguments <- c(
        "--build-hash-table", "true",
        "--ht-reference", reference_fasta,
        "--output-directory", index_directory,
        "--ht-num-threads", as.character(threads),
        "--ht-size", hash_size,
        "--ht-mem-limit", memory_limit,
        "--ht-seed-len", as.character(seed_length),
        "--ht-ref-seed-interval", format(seed_interval, scientific = FALSE, trim = TRUE),
        if (length(mask_bed)) c("--ht-mask-bed", mask_bed),
        if (length(decoys)) c("--ht-decoys", decoys),
        if (length(max_multi_base_seeds)) {
          c("--ht-max-multi-base-seeds", as.character(max_multi_base_seeds))
        }
      )
      result <- .rdm_run_process(
        operation = "build_index",
        executable = executables@dragen_os,
        arguments = arguments,
        outputs = outputs,
        result_class = RdragmapIndexBuildResult,
        result_properties = list(index = RdragmapIndex(directory = index_directory))
      )
      if (rdragmap_is_error(result)) return(result)
      completed <- TRUE
      result
    }
  )
}
