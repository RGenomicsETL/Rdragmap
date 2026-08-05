# building all available system tests

TEST_BUILD_DIR=$(DRAGEN_OS_BUILD)/test

ifeq (1,$(HAS_GTEST))
system_tests:=$(patsubst $(DRAGEN_OS_TEST_DIR)/%.cpp,%,$(wildcard $(DRAGEN_OS_TEST_DIR)/*Gtest.cpp))
system_tests:=$(filter-out $(system_skipped), $(system_tests))

# These are deterministic regressions with no external reference fixture.
self_contained_system_tests:=MappingStatsGtest RawCrcGtest
# These imported exploratory programs require a particular historical human
# index and contain hard-coded reference or extension-table coordinates.
reference_system_tests:=ExtendTableGtest HashtableGtest MapperGtest
unclassified_system_tests:=$(filter-out $(self_contained_system_tests) $(reference_system_tests),$(system_tests))
ifneq (,$(unclassified_system_tests))
$(error Classify new system tests as self-contained or reference-specific: $(unclassified_system_tests))
endif

self_contained_test_programs:=$(self_contained_system_tests:%=$(TEST_BUILD_DIR)/%)
reference_test_programs:=$(reference_system_tests:%=$(TEST_BUILD_DIR)/%)

.PHONY: test test-programs reference-test-programs
test-programs: $(self_contained_test_programs)
reference-test-programs: $(reference_test_programs)
test: test-programs
	@set -e; for test_program in $(self_contained_test_programs); do \
		$(ECHO) "running $$test_program"; \
		"$$test_program"; \
	done
all: test

define SYSTEM_TEST

system_tool := $(1)

$(TEST_BUILD_DIR)/$(1).o: $(DRAGEN_OS_TEST_DIR)/$(1).cpp $(TEST_BUILD_DIR)/$(1).d $(TEST_BUILD_DIR)/.sentinel
	$(SILENT_SE) $$(CXX) $$(DEPFLAGS) $$(CPPFLAGS) $$(GTEST_CPPFLAGS) $$(CXXFLAGS) -c -o $$@ $$< && $$(POSTCOMPILE)

$(TEST_BUILD_DIR)/$(1): $(TEST_BUILD_DIR)/$(1).o $(libraries)
	$(SILENT_SE) $$(CXX) $$(CPPFLAGS) $$(GTEST_CPPFLAGS) $$(CXXFLAGS) -o $$@ $$< $$(libraries)  $(GTEST_LDFLAGS) -lgtest_main -lgtest $$(LDFLAGS)

#$(DRAGEN_OS_BUILD)/system/$(system_tool).d: ;
include $(wildcard $(TEST_BUILD_DIR)/$(1).d)

endef # define SYSTEM_TEST

$(foreach t,$(system_tests),$(eval $(call SYSTEM_TEST,$(t))))
endif

# building tools that are independent of gtest

system_tools:=$(patsubst $(DRAGEN_OS_TEST_DIR)/%.cpp,%,$(wildcard $(DRAGEN_OS_TEST_DIR)/*.cpp))
system_tools:=$(filter-out %Gtest, $(system_tools))

tools_programs: $(system_tools:%=$(TEST_BUILD_DIR)/%)
all: tools_programs

define SYSTEM_TOOL

system_tool := $(1)

$(TEST_BUILD_DIR)/$(1).o: $(DRAGEN_OS_TEST_DIR)/$(1).cpp $(TEST_BUILD_DIR)/$(1).d $(TEST_BUILD_DIR)/.sentinel
	$(SILENT_SE) $$(CXX) $$(DEPFLAGS) $$(CPPFLAGS) $$(CXXFLAGS) -c -o $$@ $$< && $$(POSTCOMPILE)

$(TEST_BUILD_DIR)/$(1): $(TEST_BUILD_DIR)/$(1).o $(libraries)
	$(SILENT_SE) $$(CXX) $$(CPPFLAGS) $$(CXXFLAGS) -o $$@ $$< $$(libraries) $$(LDFLAGS)

#$(DRAGEN_OS_BUILD)/system/$(system_tool).d: ;
include $(wildcard $(TEST_BUILD_DIR)/$(1).d)

endef # define SYSTEM_TOOL

$(foreach t,$(system_tools),$(eval $(call SYSTEM_TOOL,$(t))))

