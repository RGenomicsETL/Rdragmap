#' Align FASTQ reads with a DRAGMAP v8 reference index
#'
#' Runs the package-owned `dragen-os` executable once and writes SAM plus native
#' mapping metrics beside `output_sam`. Paired input also writes native
#' insert-size statistics. The wrapper preserves map/align order by default so
#' that the native SAM ordering remains deterministic.
#'
#' @param index A validated `RdragmapIndex`.
#' @param read1 Absolute first FASTQ path, optionally gzip-compressed.
#' @param output_sam Absolute, not-yet-existing `.sam` output path.
#' @param read2 Empty or one absolute mate FASTQ path.
#' @param executables Explicit executable resolution from
#'   `rdragmap_executables()`.
#' @param read_group_id Read-group identifier recorded in the SAM header.
#' @param sample_name Read-group sample recorded in the SAM header.
#' @param threads Positive mapper/aligner worker count.
#' @param fastq_offset FASTQ quality offset, `33L` or `64L`.
#' @param enable_sampling Whether the native program estimates paired-end
#'   insert-size parameters from the input.
#' @param preserve_order Whether to preserve deterministic map/align order.
#' @param mmap_reference Whether to memory-map the decompressed reference.
#' @return `RdragmapAlignmentResult` or an `RdragmapErrorValue`.
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
#' if (!rdragmap_is_error(built)) {
#'   aligned <- rdragmap_align(
#'     index = built@index,
#'     read1 = system.file("extdata", "one.fastq", package = "Rdragmap"),
#'     output_sam = file.path(work, "example.sam"),
#'     read_group_id = "tiny",
#'     sample_name = "tiny",
#'     threads = 1L,
#'     enable_sampling = FALSE
#'   )
#'   if (!rdragmap_is_error(aligned)) aligned@outputs
#' }
#' unlink(work, recursive = TRUE, force = TRUE)
#' }
#' @export
rdragmap_align <- function(
  index,
  read1,
  output_sam,
  read2 = character(),
  executables = rdragmap_executables(),
  read_group_id = "1",
  sample_name = "none",
  threads = 1L,
  fastq_offset = 33L,
  enable_sampling = TRUE,
  preserve_order = TRUE,
  mmap_reference = FALSE
) {
  .rdm_contract_call(
    code = "invalid_alignment_request",
    details = list(api = "rdragmap_align"),
    expression = {
      index <- .rdm_assert_index(index)
      if (rdragmap_is_error(index)) return(index)
      read1 <- .rdm_assert_absolute_path(read1, "read1")
      output_sam <- .rdm_assert_absolute_path(output_sam, "output_sam")
      .rdm_validate_optional_path(read2, "read2")
      executables <- .rdm_assert_executables(executables)
      if (rdragmap_is_error(executables)) return(executables)
      read_group_id <- .rdm_assert_header_value(read_group_id, "read_group_id")
      sample_name <- .rdm_assert_header_value(sample_name, "sample_name")
      threads <- .rdm_assert_integer(threads, "threads", 1L, .Machine$integer.max)
      fastq_offset <- .rdm_assert_integer(fastq_offset, "fastq_offset", 33L, 64L)
      if (!fastq_offset %in% c(33L, 64L)) {
        .rdm_signal_contract_violation(
          "fastq_offset must be 33L or 64L",
          code = "invalid_fastq_offset"
        )
      }
      enable_sampling <- .rdm_assert_flag(enable_sampling, "enable_sampling")
      preserve_order <- .rdm_assert_flag(preserve_order, "preserve_order")
      mmap_reference <- .rdm_assert_flag(mmap_reference, "mmap_reference")

      prefix <- .rdm_output_prefix(output_sam)
      output_directory <- dirname(output_sam)
      outputs <- c(
        list(
          sam = output_sam,
          mapping_metrics = file.path(
            output_directory,
            paste0(prefix, ".mapping_metrics.csv")
          )
        ),
        if (length(read2)) {
          list(insert_stats = file.path(
            output_directory,
            paste0(prefix, ".insert-stats.tab")
          ))
        }
      )
      inputs <- c(list(read1 = read1), if (length(read2)) list(read2 = read2))
      ready <- .rdm_preflight(
        operation = "align",
        executable = executables@dragen_os,
        inputs = inputs,
        outputs = outputs
      )
      if (rdragmap_is_error(ready)) return(ready)

      arguments <- c(
        "--ref-dir", index@directory,
        "--output-directory", output_directory,
        "--output-file-prefix", prefix,
        "--RGID", read_group_id,
        "--RGSM", sample_name,
        "--num-threads", as.character(threads),
        "--fastq-offset", as.character(fastq_offset),
        "--enable-sampling", tolower(as.character(enable_sampling)),
        "--preserve-map-align-order", tolower(as.character(preserve_order)),
        "--mmap-reference", tolower(as.character(mmap_reference)),
        "-1", read1,
        if (length(read2)) c("-2", read2)
      )
      .rdm_run_process(
        operation = "align",
        executable = executables@dragen_os,
        arguments = arguments,
        outputs = outputs,
        result_class = RdragmapAlignmentResult,
        result_properties = list(index = index, paired = length(read2) == 1L)
      )
    }
  )
}
