#!/usr/bin/env zsh
#shellspec shell=zsh

###############################################################################
# Section Registry Tests
#
# Tests for lib/app/section_registry.sh
###############################################################################

Describe 'lib/app/section_registry.sh'
  Include lib/app/section_registry.sh

  BeforeEach 'reset_registry'

  reset_registry() {
    SECTION_REGISTRY_TOOLS=()
    SECTION_REGISTRY_NETWORK=()
  }

  Describe 'register_section function'
    It 'is defined'
      When call type register_section
      The status should be success
    End

    It 'registers section with tools'
      When call register_section "test_section" --tools "curl" "jq"
      The value "${SECTION_REGISTRY_TOOLS[test_section]}" should equal "curl jq"
    End

    It 'registers section with network requirement'
      When call register_section "test_section" --network
      The value "${SECTION_REGISTRY_NETWORK[test_section]}" should equal "true"
    End

    It 'registers section with both tools and network'
      When call register_section "test_section" --tools "curl" --network
      The value "${SECTION_REGISTRY_TOOLS[test_section]}" should equal "curl"
      The value "${SECTION_REGISTRY_NETWORK[test_section]}" should equal "true"
    End

    It 'defaults network to false when not specified'
      When call register_section "test_section" --tools "curl"
      The value "${SECTION_REGISTRY_NETWORK[test_section]}" should equal "false"
    End
  End

  Describe 'section_requires_network function'
    It 'returns success for network sections'
      register_section "net_section" --network
      When call section_requires_network "net_section"
      The status should be success
    End

    It 'returns failure for non-network sections'
      register_section "local_section" --tools "awk"
      When call section_requires_network "local_section"
      The status should be failure
    End

    It 'returns failure for unregistered sections'
      When call section_requires_network "nonexistent"
      The status should be failure
    End
  End

  Describe 'section_get_tools function'
    It 'returns tools list'
      register_section "test_section" --tools "curl" "jq" "awk"
      When call section_get_tools "test_section"
      The output should equal "curl jq awk"
    End

    It 'returns empty for section with no tools'
      register_section "test_section" --network
      When call section_get_tools "test_section"
      The output should equal ""
    End
  End

  Describe 'section_is_registered function'
    It 'returns success for registered section'
      register_section "test_section" --tools "curl"
      When call section_is_registered "test_section"
      The status should be success
    End

    It 'returns failure for unregistered section'
      When call section_is_registered "nonexistent"
      The status should be failure
    End
  End

  Describe 'section_check_deps function'
    It 'returns success when all tools available'
      register_section "test_section" --tools "ls" "cat"
      When call section_check_deps "test_section"
      The status should be success
    End

    It 'returns failure for missing tool'
      register_section "test_section" --tools "nonexistent_tool_xyz"
      When call section_check_deps "test_section"
      The status should be failure
      The stderr should include "tool:nonexistent_tool_xyz"
    End
  End

  Describe 'section_list_all function'
    It 'lists all registered sections'
      register_section "section_a" --tools "curl"
      register_section "section_b" --network
      register_section "section_c" --tools "jq" --network
      When call section_list_all
      The output should include "section_a"
      The output should include "section_b"
      The output should include "section_c"
    End
  End
End
