############################################################
##
## DRAGEN Open Source Software
## Copyright (c) 2019-2020 Illumina, Inc.
## All rights reserved.
##
## This software is provided under the terms and conditions of the
## GNU GENERAL PUBLIC LICENSE Version 3
##
## You should have received a copy of the GNU GENERAL PUBLIC LICENSE Version 3
## along with this program. If not, see
## <https://github.com/illumina/licenses/>.
##
############################################################
##
## To configure the build, see config.mk
##
############################################################

include config.mk

all: $(programs:%=$(DRAGEN_OS_BUILD)/%)

.PHONY: clean
clean:
	$(RMDIR) $(DRAGEN_OS_BUILD_DIR_BASE)

.PHONY: help
help: $(DRAGEN_OS_ROOT_DIR)/README.md
	cat $<
	
.PHONY: help-targets
help-targets:
	@$(ECHO) 'Default:   all'
	@$(ECHO) 'Help:      help help-targets'
	@$(ECHO) 'Cleanup:   clean'
	@$(ECHO) 'Install:   install'
	@$(ECHO) 'Docs:      docs'
	@$(ECHO) 'SIMD:      simd-info'
	@$(ECHO) 'Pedantic:  pedantic'
	@$(ECHO) 'Compile:   native-libraries'
	@$(ECHO) 'Test:      test'
	@$(ECHO) 'Validate:  compatibility-check'
	@$(ECHO) 'Libraries: $(library_targets)'

R_SCRIPT?=Rscript
.PHONY: docs
docs:
	$(R_SCRIPT) $(DRAGEN_OS_ROOT_DIR)/meta/render-docs.R

.PHONY: simd-info
simd-info:
	@$(ECHO) 'compiler target: ' "$$($(CXX) -dumpmachine 2>/dev/null || echo unknown)"
	@$(ECHO) 'portable SIMDe baseline: yes'
	@$(ECHO) 'native AVX2 SSW object: $(DRAGMAP_HAVE_AVX2)'

.PHONY: pedantic
pedantic:
	$(DRAGEN_OS_ROOT_DIR)/meta/check-pedantic.sh

.PHONY: compatibility-check
compatibility-check:
	$(DRAGEN_OS_ROOT_DIR)/meta/check-compatibility.sh

############################################################
##
## Rules and includes for the actual build as needed.
## empty MAKECMDGOALS defaults to "all". Inclusion must happen if any goal is not in "clean help"
##
############################################################
ifneq ($(filter-out clean help, $(or $(MAKECMDGOALS), all)),)

# Dependencies are initially generated with ".Td" extension to avoid issues if compiling fails afterwards
# and a POSTCOMPILE operation is needed to rename the file with the final ".d" extension
.PRECIOUS: %.d
DEPFLAGS = -MT $@ -MMD -MP -MF $(@:%.o=%.Td)
POSTCOMPILE ?= mv -f $(@:%.o=%.Td) $(@:%.o=%.d)
%.d: ;

# use a .sentinel file as a proxy to directories to avoid time stamp galore
.PRECIOUS: %/.sentinel
%/.sentinel:
	@mkdir -p $* && touch $@

# This header uses a Boost diagnostic macro. Compile it before any other
# project header so an accidental transitive dependency cannot mask a missing
# direct include in native or package-owned builds.
.PHONY: check-debug-header
check-debug-header: $(DRAGEN_OS_BUILD)/.sentinel
	$(SILENT) printf '%s\n' '#include "common/Debug.hpp"' | $(CXX) $(CPPFLAGS) $(CXXFLAGS) -x c++ -c -o /dev/null -
all: check-debug-header

include $(wildcard $(DRAGEN_OS_BUILD)/testRunner.d)

# side effects:
#  - builds 'libraries' variable required for linking programs, integration and system tests
#  - builds and executes unit and integration tests for each librarry
ssw_lib_dirs_aux:=$(SSW_LIBS)
include $(foreach lib_dir, $(SSW_LIBS), $(DRAGEN_OS_MAKE_DIR)/ssw_lib.mk)
dragen_stub_lib_dirs_aux:=$(DRAGEN_STUB_LIBS)
include $(foreach lib_dir, $(DRAGEN_STUB_LIBS), $(DRAGEN_OS_MAKE_DIR)/dragen_stub_lib.mk)
dragen_lib_dirs_aux:=$(DRAGEN_LIBS)
include $(foreach lib_dir, $(DRAGEN_LIBS), $(DRAGEN_OS_MAKE_DIR)/dragen_lib.mk)
lib_dirs_aux:=$(DRAGEN_OS_LIBS)
include $(foreach lib_dir, $(DRAGEN_OS_LIBS), $(DRAGEN_OS_MAKE_DIR)/lib.mk)

programs_aux:=$(programs)
include $(foreach program, $(programs), $(DRAGEN_OS_MAKE_DIR)/program.mk)

# programs for system tests
ifeq (1,${HAS_GTEST})
include $(DRAGEN_OS_MAKE_DIR)/tests.mk
endif

include $(DRAGEN_OS_MAKE_DIR)/install.mk

# Build every translation unit into static libraries without linking a host
# executable. This is the cross-compiler authority for aarch64/NEON.
.PHONY: native-libraries
native-libraries: $(library_targets)
endif

############################################################
##
## Tracing make variables
## Only add these targets if the goal is to print as it adds
## spurious targets for all non-print goals specified on the command line
##
############################################################
ifneq (,$(filter print-%, $(MAKECMDGOALS)))
print-%: ; @$(error $* is $($*) (from $(origin $*)))
$(filter-out print-%, $(MAKECMDGOALS)): $(filter print-%, $(MAKECMDGOALS))
endif
