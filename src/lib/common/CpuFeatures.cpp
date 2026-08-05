/**
 ** Rdragmap portability additions
 ** Copyright (c) 2026 Sounkou Mahamane Toure
 **
 ** This software is provided under the terms of the GNU General Public
 ** License Version 3, consistent with the DRAGMAP source distribution.
 **/

#include "common/CpuFeatures.hpp"

namespace dragenos {
namespace common {

bool cpuSupportsAvx2() noexcept
{
#if (defined(__x86_64__) || defined(__i386__)) && (defined(__GNUC__) || defined(__clang__))
  /* __builtin_cpu_supports includes the operating-system AVX state check. */
  __builtin_cpu_init();
  return __builtin_cpu_supports("avx2");
#else
  return false;
#endif
}

}  // namespace common
}  // namespace dragenos
