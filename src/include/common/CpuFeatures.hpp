/**
 ** Rdragmap portability additions
 ** Copyright (c) 2026 Sounkou Mahamane Toure
 **
 ** This software is provided under the terms of the GNU General Public
 ** License Version 3, consistent with the DRAGMAP source distribution.
 **/

#ifndef COMMON_CPU_FEATURES_HPP
#define COMMON_CPU_FEATURES_HPP

namespace dragenos {
namespace common {

/* True only when both the x86 CPU and operating system can execute AVX2. */
bool cpuSupportsAvx2() noexcept;

}  // namespace common
}  // namespace dragenos

#endif  // COMMON_CPU_FEATURES_HPP
