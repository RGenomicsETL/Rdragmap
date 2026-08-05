/**
 ** DRAGEN Open Source Software
 ** Copyright (c) 2019-2020 Illumina, Inc.
 ** All rights reserved.
 **
 ** This software is provided under the terms and conditions of the
 ** GNU GENERAL PUBLIC LICENSE Version 3
 **
 ** You should have received a copy of the GNU GENERAL PUBLIC LICENSE Version 3
 ** along with this program. If not, see
 ** <https://github.com/illumina/licenses/>.
 **
 **/

#ifndef ALIGN_VECTOR_SMITH_WATERMAN_HPP
#define ALIGN_VECTOR_SMITH_WATERMAN_HPP

#include "align/SimilarityScores.hpp"
#include "common/CpuFeatures.hpp"
#include "common/DragenLogger.hpp"
#include "ssw/ssw.hpp"

#include "align/Alignment.hpp"
#include "align/Database.hpp"
#include "align/Query.hpp"

namespace dragenos {
namespace align {

class VectorSmithWaterman {
public:
  VectorSmithWaterman(
      const SimilarityScores& similarity, const int gapInit, const int gapExtend, const int unclipScore = 0)
    : similarity_(similarity),
      gapInit_(gapInit),
      gapExtend_(gapExtend),
      unclipScore_(unclipScore),
#if defined(DRAGMAP_HAVE_AVX2) && DRAGMAP_HAVE_AVX2
      useAvx2_(common::cpuSupportsAvx2()),
#endif
      profileSse2_({NULL, NULL}),
      profileRevSse2_({NULL, NULL})
#if defined(DRAGMAP_HAVE_AVX2) && DRAGMAP_HAVE_AVX2
      ,
      profileAvx2_({NULL, NULL}),
      profileRevAvx2_({NULL, NULL})
#endif
  {
    sswAlphabetSize_ = 16;
    sswScoringMat_   = (int8_t*)calloc(sswAlphabetSize_ * sswAlphabetSize_, sizeof(int8_t));

    for (char ii = 0; ii < sswAlphabetSize_; ii++) {
      for (char jj = 0; jj < sswAlphabetSize_; jj++) {
        sswScoringMat_[ii + jj * sswAlphabetSize_] = similarity_(ii, jj);
      }
    }

    sswBias_ = ssw_get_bias(sswScoringMat_, sswAlphabetSize_);

#ifdef TRACE_VECTOR_SMITH_WATERMAN
    printf("Scoring matrix for vectorized Smith Waterman\n");
    printf("    ");
    for (char ii = 0; ii < sswAlphabetSize_; ii++) {
      printf("%5c", sequences::Read::decodeBase(ii));
    }

    printf("\n");
    for (char ii = 0; ii < sswAlphabetSize_; ii++) {
      printf("%3c ", sequences::Read::decodeBase(ii));
      for (char jj = 0; jj < sswAlphabetSize_; jj++) {
        printf("%5i", sswScoringMat_[ii + jj * sswAlphabetSize_]);
      }
      printf("\n");
    }

#endif
  }

  ~VectorSmithWaterman() { free(sswScoringMat_); }

  uint16_t align(
      const unsigned char* queryBegin,
      const unsigned char* queryEnd,
      const unsigned char* databaseBegin,
      const unsigned char* databaseEnd,
      bool                 reverseQuery,
      std::string&         cigar,
      int                  readIdx);

  void initReadContext(const unsigned char* queryBegin, const unsigned char* queryEnd, int readIdx);
  void destroyReadContext(int readIdx);

private:
  std::string convert_cigar(const s_align& s_al, const int& query_len);

  void getCigarOperations(const s_align& s_al, const int& query_len, std::string& operations);

  std::array<std::vector<unsigned char>, 2> queryRev_;
  std::array<std::vector<unsigned char>, 2> query_;
  const SimilarityScores                    similarity_;
  const int8_t                              gapInit_;
  const int8_t                              gapExtend_;
  const int8_t                              unclipScore_;
  int8_t*                                   sswScoringMat_;
  int                                       sswAlphabetSize_;
  int32_t                                   sswBias_;
  std::array<int, 2>                        querySize_;
#if defined(DRAGMAP_HAVE_AVX2) && DRAGMAP_HAVE_AVX2
  const bool                                useAvx2_;
#endif
  std::array<s_profile_sse2*, 2>            profileSse2_;
  std::array<s_profile_sse2*, 2>            profileRevSse2_;
#if defined(DRAGMAP_HAVE_AVX2) && DRAGMAP_HAVE_AVX2
  std::array<s_profile_avx2*, 2>            profileAvx2_;
  std::array<s_profile_avx2*, 2>            profileRevAvx2_;
#endif
};

}  // namespace align
}  // namespace dragenos

#endif  // #ifndef ALIGN_VECTOR_SMITH_WATERMAN_HPP
