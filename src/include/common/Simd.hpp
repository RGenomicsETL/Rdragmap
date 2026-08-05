/**
 ** Rdragmap portability additions
 ** Copyright (c) 2026 Sounkou Mahamane Toure
 **
 ** This software is provided under the terms of the GNU General Public
 ** License Version 3, consistent with the DRAGMAP source distribution.
 **/

#ifndef COMMON_SIMD_HPP
#define COMMON_SIMD_HPP

/*
 * Keep x86 intrinsic spelling in the imported DRAGMAP implementation while
 * letting SIMDe provide equivalent types and operations on non-x86 targets.
 * The ordinary build has no global x86 ISA flags. Native AVX2 is confined to
 * the separately compiled SSW translation unit and selected at runtime.
 */
#define SIMDE_ENABLE_NATIVE_ALIASES
#include <simde/x86/sse4.1.h>
#include <simde/x86/ssse3.h>

#endif  // COMMON_SIMD_HPP
