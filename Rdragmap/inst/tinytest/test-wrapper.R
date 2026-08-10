library(tinytest)

run_wrapper_test <- function() {
  fake_dragen_os <- function(directory) {
    path <- file.path(directory, "dragen-os")
    writeLines(c(
      "#!/bin/sh",
      "set -eu",
      "out=",
      "prefix=",
      "build=0",
      "paired=0",
      "write_uncompressed=0",
      "while [ $# -gt 0 ]; do",
      "  case \"$1\" in",
      "    --build-hash-table) build=1; shift 2 ;;",
      "    --output-directory) out=$2; shift 2 ;;",
      "    --output-file-prefix) prefix=$2; shift 2 ;;",
      "    --ht-write-hash-bin) write_uncompressed=$2; shift 2 ;;",
      "    -2|--fastq-file2) paired=1; shift 2 ;;",
      "    *) shift ;;",
      "  esac",
      "done",
      "if [ \"$build\" -eq 1 ]; then",
      "  for file in hash_table.cfg hash_table.cfg.bin hash_table.cmp hash_table_stats.txt reference.bin ref_index.bin repeat_mask.bin str_table.bin; do",
      "    printf x > \"$out/$file\"",
      "  done",
      "  if [ \"$write_uncompressed\" -eq 1 ]; then",
      "    printf x > \"$out/hash_table.bin\"",
      "    printf x > \"$out/extend_table.bin\"",
      "  fi",
      "else",
      "  printf sam > \"$out/$prefix.sam\"",
      "  printf metrics > \"$out/$prefix.mapping_metrics.csv\"",
      "  if [ \"$paired\" -eq 1 ]; then printf insert > \"$out/$prefix.insert-stats.tab\"; fi",
      "fi",
      "printf native-stdout"
    ), path, useBytes = TRUE)
    Sys.chmod(path, mode = "0755")
    path
  }

  root <- tempfile("rdragmap-wrapper-")
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)
  reference <- file.path(root, "reference.fa")
  read1 <- file.path(root, "reads-1.fastq")
  read2 <- file.path(root, "reads-2.fastq")
  writeLines(c(">chr1", "ACGT"), reference, useBytes = TRUE)
  writeLines(c("@read", "ACGT", "+", "IIII"), read1, useBytes = TRUE)
  writeLines(c("@read", "ACGT", "+", "IIII"), read2, useBytes = TRUE)
  executable <- fake_dragen_os(root)
  executables <- rdragmap_executables(dragen_os = executable)
  expect_true(!rdragmap_is_error(executables))
  expect_true(S7::S7_inherits(executables, RdragmapExecutables))

  index_directory <- file.path(root, "index")
  built <- rdragmap_build_index(
    reference_fasta = reference,
    index_directory = index_directory,
    executables = executables,
    threads = 1L
  )
  expect_true(!rdragmap_is_error(built))
  expect_true(S7::S7_inherits(built, RdragmapIndexBuildResult))
  expect_true(file.exists(built@index@directory))
  expect_true(all(file.exists(unlist(built@outputs))))

  output_sam <- file.path(root, "aligned.sam")
  aligned <- rdragmap_align(
    index = built@index,
    read1 = read1,
    read2 = read2,
    output_sam = output_sam,
    executables = executables,
    threads = 1L
  )
  expect_true(!rdragmap_is_error(aligned))
  expect_true(S7::S7_inherits(aligned, RdragmapAlignmentResult))
  expect_true(isTRUE(aligned@paired))
  expect_true(all(file.exists(unlist(aligned@outputs))))
  expect_equal(readLines(output_sam, warn = FALSE), "sam")

  missing_mmap <- rdragmap_align(
    index = built@index,
    read1 = read1,
    output_sam = file.path(root, "missing-mmap.sam"),
    executables = executables,
    threads = 1L,
    mmap_reference = TRUE
  )
  expect_true(rdragmap_is_error(missing_mmap))
  expect_equal(missing_mmap@code, "index_mmap_files_missing")
  expect_equal(
    sort(missing_mmap@details$missing),
    sort(c("hash_table.bin", "extend_table.bin"))
  )

  mmap_index <- rdragmap_build_index(
    reference_fasta = reference,
    index_directory = file.path(root, "mmap-index"),
    executables = executables,
    threads = 1L,
    write_uncompressed = TRUE
  )
  expect_true(!rdragmap_is_error(mmap_index))
  expect_true(all(c("hash", "extension") %in% names(mmap_index@outputs)))
  expect_true(all(file.exists(unlist(mmap_index@outputs))))
  mmap_alignment <- rdragmap_align(
    index = mmap_index@index,
    read1 = read1,
    output_sam = file.path(root, "mmap.sam"),
    executables = executables,
    threads = 1L,
    mmap_reference = TRUE
  )
  expect_true(!rdragmap_is_error(mmap_alignment))

  packaged <- rdragmap_executables()
  expect_true(!rdragmap_is_error(packaged))
  native_index <- rdragmap_build_index(
    reference_fasta = system.file("extdata", "tiny.fasta", package = "Rdragmap"),
    index_directory = file.path(root, "native-index"),
    executables = packaged,
    threads = 1L,
    hash_size = "16MB",
    write_uncompressed = TRUE
  )
  expect_true(!rdragmap_is_error(native_index))
  native_alignment <- rdragmap_align(
    index = native_index@index,
    read1 = system.file("extdata", "one.fastq", package = "Rdragmap"),
    output_sam = file.path(root, "native.sam"),
    executables = packaged,
    read_group_id = "tiny",
    sample_name = "tiny",
    threads = 1L,
    enable_sampling = FALSE,
    mmap_reference = TRUE
  )
  expect_true(!rdragmap_is_error(native_alignment))
  expect_true(file.exists(native_alignment@outputs$sam))
  mmap_sam <- readLines(native_alignment@outputs$sam, warn = FALSE)
  expect_true(length(mmap_sam) > 1L)

  compressed_alignment <- rdragmap_align(
    index = native_index@index,
    read1 = system.file("extdata", "one.fastq", package = "Rdragmap"),
    output_sam = file.path(root, "native-compressed.sam"),
    executables = packaged,
    read_group_id = "tiny",
    sample_name = "tiny",
    threads = 1L,
    enable_sampling = FALSE
  )
  expect_true(!rdragmap_is_error(compressed_alignment))
  compressed_sam <- readLines(compressed_alignment@outputs$sam, warn = FALSE)
  expect_equal(
    grep("^@", mmap_sam, invert = TRUE, value = TRUE),
    grep("^@", compressed_sam, invert = TRUE, value = TRUE)
  )

  missing <- rdragmap_executables(directory = file.path(root, "missing-bin"))
  expect_true(rdragmap_is_error(missing))
  expect_true(S7::S7_inherits(missing, RdragmapInputErrorValue))

  help <- processx::run(
    packaged@dragen_os,
    args = "--help",
    error_on_status = FALSE,
    echo = FALSE
  )
  expect_equal(as.integer(help$status), 0L)
}

run_wrapper_test()
