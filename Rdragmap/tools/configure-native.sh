#!/bin/sh
# Build the packaged dragen-os child executable with R's native toolchain.

set -eu

platform=${1:-unix}
case "$platform" in
  unix)
    exeext=
    ;;
  windows)
    echo "ERROR: Rdragmap does not currently support Windows installation" >&2
    exit 1
    ;;
  *)
    echo "ERROR: unsupported configure platform: $platform" >&2
    exit 1
    ;;
esac

if [ -z "${R_HOME:-}" ]; then
  R_HOME=$(R RHOME)
fi
r_command="$R_HOME/bin/R"
rscript_command="$R_HOME/bin/Rscript"
if [ ! -x "$r_command" ] || [ ! -x "$rscript_command" ]; then
  echo "ERROR: R_HOME does not identify a usable R installation: $R_HOME" >&2
  exit 1
fi

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
package_root=$(CDPATH='' cd -- "$script_dir/.." && pwd)
archive="$package_root/tools/dragmap-source.tar.xz"
build_root="$package_root/tools/dragmap-build"
source_root="$build_root/source"
bin_dir="$package_root/inst/dragen/bin"

if [ ! -f "$archive" ]; then
  echo "ERROR: missing pinned DRAGMAP source archive: $archive" >&2
  exit 1
fi

make_command=$("$r_command" CMD config MAKE)
cc=$("$r_command" CMD config CC)
cxx=$("$r_command" CMD config CXX17)
ar=$("$r_command" CMD config AR)
if [ -z "$make_command" ] || [ -z "$cc" ] || [ -z "$cxx" ] || [ -z "$ar" ]; then
  echo "ERROR: R did not report a complete native toolchain" >&2
  exit 1
fi

make_jobs=${RDRAGMAP_MAKE_JOBS:-2}
case "$make_jobs" in
  *[!0-9]*|'')
    echo "ERROR: RDRAGMAP_MAKE_JOBS must be a positive integer" >&2
    exit 1
    ;;
esac
if [ "$make_jobs" -lt 1 ]; then
  echo "ERROR: RDRAGMAP_MAKE_JOBS must be a positive integer" >&2
  exit 1
fi

rm -f "$bin_dir/dragen-os" "$bin_dir/dragen-os.exe"
rm -rf "$build_root"
mkdir -p "$source_root" "$bin_dir"
trap 'rm -rf "$build_root"' EXIT INT HUP TERM

"$rscript_command" -e '
args <- commandArgs(trailingOnly = TRUE)
utils::untar(args[[1L]], exdir = args[[2L]])
' "$archive" "$source_root"

run_make() {
  # R CMD config MAKE may contain implementation-specific arguments.
  # shellcheck disable=SC2086
  $make_command "$@"
}

native_executable="$source_root/build/release/dragen-os"
echo "Building Rdragmap dragen-os with $make_jobs make jobs"
run_make -j"$make_jobs" -C "$source_root" \
  HAS_GTEST=0 CC="$cc" CXX="$cxx" AR="$ar" \
  "$native_executable"

if [ ! -x "$native_executable" ]; then
  echo "ERROR: native build did not produce dragen-os" >&2
  exit 1
fi
cp "$native_executable" "$bin_dir/dragen-os${exeext}"
chmod 755 "$bin_dir/dragen-os${exeext}"
echo "Rdragmap configure: installed native executable in $bin_dir"
