DRAGEN_OS_VERSION:=0.2020.08.19
DRAGMAP_SOURCE_VERSION:=1.3.1

############################################################
##
## Operating system
##
############################################################

SHELL:=/bin/bash
UNAME_STRING:=$(shell uname -a)
# The compiler target and successful feature probes determine what is built.
# Do not reject operating-system names before the toolchain is inspected.
OS?=$(shell uname -s 2>/dev/null || echo unknown)

############################################################
##
## Compiler
##
############################################################

#GCC_BASE?=/usr
#CC=$(GCC_BASE)/bin/gcc
#CXX=$(GCC_BASE)/bin/g++

CC?=gcc
CXX?=g++

############################################################
##
## Boost Libraries
## Should work with vanilla Boost versions for CentOs 7 (1.53),
## CentOs 8 (1.66), Ubuntu 16.04.6 LTS (1.58)
##
############################################################

ifneq (,$(BOOST_ROOT))
BOOST_INCLUDEDIR?=$(BOOST_ROOT)/include
BOOST_LIBRARYDIR?=$(BOOST_ROOT)/lib
endif # ifneq (,$(BOOST_ROOT))

# C++17 owns filesystem and threading. Boost remains only for compressed
# streams and the command-line parser.
BOOST_LIBRARIES := iostreams program_options

############################################################
##
## Boost Libraries
## Should work with vanilla Boost versions for CentOs 7 (1.53),
## CentOs 8 (1.66), Ubuntu 16.04.6 LTS (1.58)
##
############################################################

HAS_GTEST?=1

ifneq (,$(GTEST_ROOT))
GTEST_INCLUDEDIR?=$(GTEST_ROOT)/include
GTEST_LIBRARYDIR?=$(GTEST_ROOT)/lib
endif # ifneq(,$(GTEST_ROOT))

############################################################
##
## Bamtools
## Not needed anymore
##
############################################################
#BAMTOOLS_ROOT?=/opt/bamtools/bamtools-2.4.1
#BAMTOOLS_INCLUDEDIR?=$(BAMTOOLS_ROOT)/include
#BAMTOOLS_LIBDIR?=$(BAMTOOLS_ROOT)/lib

#ifeq (,$(realpath $(BAMTOOLS_INCLUDEDIR)))
#$(error BAMTOOLS_INCLUDEDIR not available: $(BAMTOOLS_INCLUDEDIR): specify either BAMTOOLS_ROOT or BAMTOOLS_INCLUDEDIR)
#endif

#ifeq (,$(realpath $(BAMTOOLS_LIBDIR)))
#$(error BAMTOOLS_LIBDIR not available: $(BAMTOOLS_LIBDIR): specify either BAMTOOLS_ROOT or BAMTOOLS_LIBDIR)
#endif

############################################################
##
## Tools
##
############################################################

SILENT?=$(if $(VERBOSE),,@ $(ECHO) making $@; )
SILENT_SE?=$(if $(VERBOSE),,@ $(ECHO) making $$@; )
CAT?=cat
ECHO?=echo
EVAL?=eval
RMDIR?=rm -rf
MV?=mv

############################################################
##
## DRAGEN Open Source directory structure and source files
##
############################################################

DRAGEN_OS_ROOT_DIR?=$(realpath $(dir $(filter %Makefile, $(MAKEFILE_LIST))))
ifeq (,$(DRAGEN_OS_ROOT_DIR))
$(error Failed to infer DRAGEN_OS_ROOT_DIR from MAKEFILE_LIST: $(MAKEFILE_LIST))
endif

DRAGEN_THIRDPARTY?=$(DRAGEN_OS_ROOT_DIR)/thirdparty
DRAGEN_SRC_DIR?=$(DRAGEN_OS_ROOT_DIR)/thirdparty/dragen/src
DRAGEN_STUBS_DIR?=$(DRAGEN_OS_ROOT_DIR)/stubs/dragen/src
BAMTOOLS_STUBS_DIR?=$(DRAGEN_OS_ROOT_DIR)/stubs/bamtools/bamtools-2.4.1
SSW_SRC_DIR?=$(DRAGEN_OS_ROOT_DIR)/thirdparty/sswlib
DRAGEN_OS_SRC_DIR?=$(DRAGEN_OS_ROOT_DIR)/src
DRAGEN_OS_MAKE_DIR?=$(DRAGEN_OS_ROOT_DIR)/make
DRAGEN_OS_TEST_DIR?=$(DRAGEN_OS_ROOT_DIR)/tests
DRAGEN_OS_BUILD_DIR_BASE?=$(DRAGEN_OS_ROOT_DIR)/build

ifdef DEBUG
BUILD_TYPE=debug
else
BUILD_TYPE=release
endif
# TODO: add support for differentiating by toolset
DRAGEN_OS_BUILD_DIR?=$(DRAGEN_OS_BUILD_DIR_BASE)/$(BUILD_TYPE)
DRAGEN_OS_BUILD:=$(DRAGEN_OS_BUILD_DIR)

## List the libraries in the order where they should be statically linked
DRAGEN_OS_LIBS := common options bam fastq sequences io reference map align workflow

## List the libraries from dragen source tree in the order where they should be statically linked
# crypto follows hash_generation in the final static link order because the
# portable hash digest path calls crc32c_hw(). Inclusion prepends each archive.
DRAGEN_LIBS := host/infra/crypto common/hash_generation host/dragen_api/sampling common host/metrics

## List the libraries that pretend the dragen source tree libraries are being linked with rest of dragen source tree
DRAGEN_STUB_LIBS := host/dragen_api host/metrics host/infra/linux

SSW_LIBS := ssw

integration_skipped?=
ifdef integration_skipped
$(warning Skiping these integration tests: $(integration_skipped))
endif

############################################################
##
## Compilation and linking flags
##
############################################################

# version must be tagged in the git repo
VERSION_STRING?=$(shell git describe --tags --always --abbrev=8 2> /dev/null || echo "$(DRAGMAP_SOURCE_VERSION)-rdragmap")

CXXWARNINGS=-Werror -Wno-unused-variable -Wno-free-nonheap-object -Wno-parentheses
CWARNINGS?=-Werror -Wno-unused-variable -Wno-unused-function -Wno-format-truncation
CXXSTD?=-std=c++17

# These imported GCC tuning flags are retained only when the selected C++
# compiler accepts each under -Werror. Clang already applies comparable
# vectorization at -O2 and rejects several of the GCC-only spellings.
DRAGMAP_TUNING_CXX_FLAGS?=-ftree-vectorize -finline-functions -fpredictive-commoning -fgcse-after-reload -funswitch-loops -ftree-slp-vectorize -fvect-cost-model -fipa-cp-clone -ftree-phiprop
DRAGMAP_TUNING_CXX_FLAGS_SUPPORTED?=$(shell CXX='$(CXX)' CXX_FLAGS_TO_PROBE='$(DRAGMAP_TUNING_CXX_FLAGS)' sh $(DRAGEN_OS_ROOT_DIR)/meta/probe-cxx-flags.sh)

# RsimdDispatch pattern: keep ordinary objects on the compiler baseline and
# stage AVX2 only when the compiler targets x86 and accepts the ISA flag.
DRAGMAP_AVX2_FLAGS?=-mavx2
DRAGMAP_HAVE_AVX2?=$(shell CXX='$(CXX)' AVX2_FLAGS='$(DRAGMAP_AVX2_FLAGS)' sh meta/probe-avx2.sh)

CPPFLAGS?=-Wall -ggdb3
#some dragen sources need this
CPPFLAGS += -DLOCAL_BUILD
CPPFLAGS += -D'DRAGEN_OS_VERSION="$(DRAGEN_OS_VERSION)"' 
CPPFLAGS += -DVERSION_STRING="$(VERSION_STRING)"
CXXFLAGS+=$(CXXWARNINGS) $(CXXSTD)
CFLAGS+=$(CWARNINGS)
LDFLAGS?=

ifneq (,$(BOOST_INCLUDEDIR))
CPPFLAGS += -I $(BOOST_INCLUDEDIR)
endif
#CPPFLAGS += -I $(BAMTOOLS_INCLUDEDIR)
CPPFLAGS += -I $(DRAGEN_THIRDPARTY)
CPPFLAGS += -I $(DRAGEN_OS_SRC_DIR)/include
CPPFLAGS += -I $(DRAGEN_SRC_DIR) -I $(DRAGEN_SRC_DIR)/common/public -I $(DRAGEN_SRC_DIR)/host/dragen_api/sampling
CPPFLAGS += -I $(DRAGEN_SRC_DIR)/host/infra/public -I $(DRAGEN_SRC_DIR)/host/metrics/public
CPPFLAGS += -I $(SSW_SRC_DIR)
CPPFLAGS += -I $(DRAGEN_STUBS_DIR)/host/dragen_api -I $(DRAGEN_STUBS_DIR)/host/dragen_api/dbam  
CPPFLAGS += -I $(DRAGEN_STUBS_DIR)/host/infra/public -I $(DRAGEN_STUBS_DIR)/host/metrics/public
CPPFLAGS += -I $(BAMTOOLS_STUBS_DIR)/include
CPPFLAGS += -I $(DRAGEN_THIRDPARTY)/simde
ifeq (1,$(DRAGMAP_HAVE_AVX2))
CPPFLAGS += -DDRAGMAP_HAVE_AVX2=1
endif

ifneq (,$(BOOST_LIBRARYDIR))
LDFLAGS += -L $(BOOST_LIBRARYDIR)
endif
LDFLAGS += $(BOOST_LIBRARIES:%=-lboost_%)

ifdef DEBUG
CPPFLAGS += -O0 -ggdb3 -femit-class-debug-always -fno-omit-frame-pointer
ifeq ($(DEBUG),glibc)
ifeq (,$(BOOST_LIBRARYDIR))
$(error BOOST_LIBRARYDIR is not set. make sure that LD_LIBRARY_PATH and BOOST_LIBRARYDIR point to boost built with _GLIBCXX_DEBUG)
endif #ifeq (,$(BOOST_LIBRARYDIR))
CPPFLAGS += -D_GLIBCXX_DEBUG
endif #ifeq ($(DEBUG),glibc)
#CPPFLAGS += -pg -fstack-usage -fprofile-arcs -ftest-coverage
LDFLAGS += -lgcov -Wl,--exclude-libs=ALL
else # non DEBUG
#CPPFLAGS += -O3 -march=native # Not particularly great
#CPPFLAGS += -O3 -march=skylake-avx512 # same as above

# this seems to be fastest for fastq parsing. mainly because it manages to put proper PSUBB instruction for subtracing q0 from qscore chars
CPPFLAGS += -g -O2 $(DRAGMAP_TUNING_CXX_FLAGS_SUPPORTED)

# this seems slightly slower than above
#CXXFLAGS += -g -mavx2 -O2 -ftree-vectorize -finline-functions -fpredictive-commoning -fgcse-after-reload -funswitch-loops -ftree-slp-vectorize -fvect-cost-model -fipa-cp-clone -ftree-phiprop
endif # if DEBUG

ifdef ASAN
CPPFLAGS += -fsanitize=address
ifeq ($(ASAN),all)
CPPFLAGS += -fsanitize=leak -fsanitize=undefined # Not supported by g++ 4.8
endif # ifeq ($(ASAN,all)
endif # ASAN 


LDFLAGS+= -lz -lpthread

ifdef STATIC_LIBCPP
LDFLAGS+= -static-libstdc++
else
LDFLAGS+= -lstdc++
endif

#LDFLAGS+= -lz -lstdc++ -lrt -lgomp -lpthread

ifneq (,$(GTEST_INCLUDEDIR))
GTEST_CPPFLAGS+= -I $(GTEST_INCLUDEDIR)
endif

ifneq (,$(GTEST_LIBRARYDIR))
GTEST_LDFLAGS+= -L $(GTEST_LIBRARYDIR)
endif # ifneq (,$(GTEST_LIBRARYDIR))

GTEST_LDFLAGS+= -lgtest_main -lgtest

############################################################
##
## Basic verification
##
############################################################

ifneq (,$(BOOST_INCLUDEDIR))
ifeq ($(wildcard $(BOOST_INCLUDEDIR)),)
$(error BOOST_INCLUDEDIR: $(BOOST_INCLUDEDIR): directory not found: make sure that the environment variables BOOST_ROOT or BOOST_INCLUDEDIR are correctly set)
endif
endif

############################################################
##
## Structuring the source
##
############################################################

sources := $(wildcard $(DRAGEN_OS_SRC_DIR)/*.cpp)
programs := $(sources:$(DRAGEN_OS_SRC_DIR)/%.cpp=%)
all_lib_sources := $(wildcard $(DRAGEN_OS_SRC_DIR)/lib/*/*.cpp)
#all_lib_sources += $(wildcard $(DRAGEN_OS_SRC_DIR)/lib/*/*.c)
found_lib_dirs := $(sort $(patsubst %/, %, $(dir $(all_lib_sources:$(DRAGEN_OS_SRC_DIR)/lib/%=%))))
all_dragen_lib_sources += $(wildcard $(DRAGEN_SRC_DIR)/*/*/*.cpp) $(wildcard $(DRAGEN_SRC_DIR)/*/*/*/*.cpp)
all_dragen_lib_sources += $(wildcard $(DRAGEN_SRC_DIR)/*/*/*.c) $(wildcard $(DRAGEN_SRC_DIR)/*/*/*/*.c)
found_dragen_lib_dirs := $(sort $(patsubst %/, %, $(dir $(all_dragen_lib_sources:$(DRAGEN_SRC_DIR)/%=%))))
ifneq ($(sort $(DRAGEN_OS_LIBS) $(DRAGEN_LIBS)),$(sort $(found_lib_dirs) $(found_dragen_lib_dirs)))
$(error found libraries: $(sort $(found_dragen_lib_dirs) $(found_lib_dirs)): expected libraries: $(sort $(DRAGEN_OS_LIBS) $(DRAGEN_LIBS)): verify that the DRAGEN_OS_LIBS and DRAGEN_LIBS variables in config.mk lists the correct libraries)
endif

