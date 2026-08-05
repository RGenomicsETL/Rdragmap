#ifndef __CRC32_HW_H__
#define __CRC32_HW_H__
#include <inttypes.h>
#include <stdbool.h>
#include <stddef.h>

#include "fast_nonvector_crc32c.h"

#ifdef __cplusplus
extern "C" {
#endif

uint32_t crc32c_hw(uint32_t crc, const void* buf, size_t len);
bool     machine_has_sse42();

/* Match the raw state transition of x86 crc32 instructions: no initial or
 * final complement. crc32c_hw() implements the conventional complemented
 * CRC-32C API, so complementing both sides preserves the imported hash format.
 */
static inline uint32_t crc32c_raw(uint32_t crc, const void* buf, size_t len)
{
  /* Every imported local hash call consumes one 64-bit record. The fixed-size
   * table kernel is both ISA-portable and exactly equivalent to crc32q. */
  if (len == 8) return fastCrc32c8(crc, (const uint8_t*)buf);
  return ~crc32c_hw(~crc, buf, len);
}

#ifdef __cplusplus
}
#endif

#endif
