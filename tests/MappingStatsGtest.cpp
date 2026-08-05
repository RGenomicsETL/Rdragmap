/**
 ** Rdragmap regression tests
 ** Copyright (c) 2026 Sounkou Mahamane Toure
 **
 ** This software is provided under the terms of the GNU General Public
 ** License Version 3, consistent with the DRAGMAP source distribution.
 **/

#include <sstream>
#include <vector>

#include <gtest/gtest.h>

#include "align/Alignment.hpp"
#include "mapping_stats.hpp"
#include "sequences/Read.hpp"

namespace {

struct SerializedRecord {
  std::vector<char> readBuffer;
  std::vector<char> alignmentBuffer;

  SerializedRecord(const dragenos::align::Alignment& alignment, unsigned readLength)
  {
    dragenos::sequences::Read read;
    dragenos::sequences::Read::Name name{'r', 'e', 'a', 'd'};
    dragenos::sequences::Read::Bases bases(readLength, 1);
    dragenos::sequences::Read::Qualities qualities(readLength, 30);
    read.init(std::move(name), std::move(bases), std::move(qualities), 0, 0);

    readBuffer.resize(dragenos::sequences::SerializedRead::getByteSize(read));
    serializedRead() << read;
    alignmentBuffer.resize(dragenos::align::SerializedAlignment::getByteSize(alignment));
    serializedAlignment() << alignment;
  }

  dragenos::sequences::SerializedRead& serializedRead()
  {
    return *reinterpret_cast<dragenos::sequences::SerializedRead*>(readBuffer.data());
  }

  dragenos::align::SerializedAlignment& serializedAlignment()
  {
    return *reinterpret_cast<dragenos::align::SerializedAlignment*>(alignmentBuffer.data());
  }
};

dragenos::align::Alignment mappedAlignment()
{
  dragenos::align::Alignment alignment;
  alignment.resetFlags();
  alignment.setPosition(0);
  alignment.setReference(0);
  alignment.setMapq(60);
  alignment.setMismatchCount(0);
  return alignment;
}

}  // namespace

TEST(MappingStats, ResetClearsEveryMapqBin)
{
  std::ostringstream log;
  ReadGroupAlignmentCounts stats(log);
  for (uint64_t& count : stats.m_mapq_hist) count = 7;
  stats.reset();
  for (uint64_t count : stats.m_mapq_hist) EXPECT_EQ(0U, count);
}

TEST(MappingStats, CountAllIncludesDuplicateCounters)
{
  std::ostringstream log;
  ReadGroupAlignmentCounts stats(log);
  auto alignment = mappedAlignment();
  alignment.setFlags(dragenos::align::AlignmentHeader::DUPLICATE);
  alignment.cigar().emplace_back(dragenos::align::Cigar::ALIGNMENT_MATCH, 10);
  SerializedRecord record(alignment, 10);

  stats.addRecord(record.serializedAlignment(), record.serializedRead());

  EXPECT_EQ(1U, stats.m_numRecords);
  EXPECT_EQ(1U, stats.m_numDuplicatesMarked);
  EXPECT_EQ(1U, stats.m_numDuplicatesRemoved);
}

TEST(MappingStats, UnmappedUnknownEditDistanceDoesNotUnderflow)
{
  std::ostringstream log;
  ReadGroupAlignmentCounts stats(log);
  dragenos::align::Alignment alignment;
  alignment.resetFlags(dragenos::align::AlignmentHeader::UNMAPPED);
  SerializedRecord record(alignment, 10);

  stats.addRecord(record.serializedAlignment(), record.serializedRead());

  EXPECT_EQ(0U, stats.m_numMismatchesR1);
}

TEST(MappingStats, RefSkipDoesNotConsumeFollowingCigarOperation)
{
  std::ostringstream log;
  ReadGroupAlignmentCounts stats(log);
  auto alignment = mappedAlignment();
  alignment.cigar().emplace_back(dragenos::align::Cigar::ALIGNMENT_MATCH, 10);
  alignment.cigar().emplace_back(dragenos::align::Cigar::SKIP, 5);
  alignment.cigar().emplace_back(dragenos::align::Cigar::ALIGNMENT_MATCH, 7);
  SerializedRecord record(alignment, 17);

  stats.addRecord(record.serializedAlignment(), record.serializedRead());

  EXPECT_EQ(1U, stats.m_splicedReads);
  EXPECT_EQ(17U, stats.m_numAllQ30BasesR1);
  EXPECT_EQ(17U, stats.m_numNonDupNonClippedQ30Bases);
}
