#include <array>
#include <cstdint>

#include <gtest/gtest.h>

extern "C" {
#include "crc32_hw.h"
}

TEST(RawCrc, MatchesImportedX86HashStateTransitions)
{
  const std::array<uint8_t, 8> first{{0, 1, 2, 3, 4, 5, 6, 7}};
  const std::array<uint8_t, 8> second{{8, 9, 10, 11, 12, 13, 14, 15}};

  const uint32_t firstCrc = crc32c_raw(0, first.data(), first.size());
  EXPECT_EQ(UINT32_C(0x06040EB1), firstCrc);
  EXPECT_EQ(UINT32_C(0x76AB22E2), crc32c_raw(0, second.data(), second.size()));
  EXPECT_EQ(
      UINT32_C(0x9BB99201),
      crc32c_raw(firstCrc, second.data(), second.size()));
}
