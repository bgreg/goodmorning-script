#!/usr/bin/env zsh
#shellspec shell=zsh

###############################################################################
# Validation Helpers Tests
#
# Tests for lib/setup/validation_helpers.sh
###############################################################################

Describe 'lib/setup/validation_helpers.sh'
  Include "$PWD/spec/spec_helper.sh"

  setup() {
    source "$PWD/lib/app/colors.sh"
    source "$PWD/lib/app/view_helpers.sh"
    source "$PWD/lib/setup/validation_helpers.sh"
    LOG_FILE="/dev/null"
  }

  Before 'setup'

  Describe 'validation_reset_counters function'
    It 'is defined'
      When call type validation_reset_counters
      The status should be success
      The output should include "function"
    End

    It 'resets all counters to zero'
      VALIDATION_PASSED=5
      VALIDATION_FAILED=3
      VALIDATION_WARNED=2
      When call validation_reset_counters
      The variable VALIDATION_PASSED should equal 0
      The variable VALIDATION_FAILED should equal 0
      The variable VALIDATION_WARNED should equal 0
    End
  End

  Describe 'validation_pass function'
    It 'is defined'
      When call type validation_pass
      The status should be success
      The output should include "function"
    End

    It 'increments VALIDATION_PASSED counter'
      VALIDATION_PASSED=0
      When call validation_pass "Test check"
      The variable VALIDATION_PASSED should equal 1
    End

    It 'displays the check description'
      VALIDATION_PASSED=0
      When call validation_pass "Test check"
      The output should include "Test check"
    End
  End

  Describe 'validation_fail function'
    It 'is defined'
      When call type validation_fail
      The status should be success
      The output should include "function"
    End

    It 'increments VALIDATION_FAILED counter'
      VALIDATION_FAILED=0
      When call validation_fail "Test check"
      The variable VALIDATION_FAILED should equal 1
    End

    It 'displays failure detail when provided'
      VALIDATION_FAILED=0
      When call validation_fail "Test check" "Detail message"
      The output should include "Detail message"
    End
  End

  Describe 'validation_warn function'
    It 'is defined'
      When call type validation_warn
      The status should be success
      The output should include "function"
    End

    It 'increments VALIDATION_WARNED counter'
      VALIDATION_WARNED=0
      When call validation_warn "Test check"
      The variable VALIDATION_WARNED should equal 1
    End

    It 'displays warning detail when provided'
      VALIDATION_WARNED=0
      When call validation_warn "Test check" "Warning detail"
      The output should include "Warning detail"
    End
  End

  Describe 'validation_info function'
    It 'is defined'
      When call type validation_info
      The status should be success
      The output should include "function"
    End

    It 'displays info message'
      When call validation_info "Info message"
      The output should include "Info message"
    End
  End

  Describe 'validation_section function'
    It 'is defined'
      When call type validation_section
      The status should be success
      The output should include "function"
    End

    It 'displays section title'
      When call validation_section "Test Section"
      The output should include "Test Section"
    End

    It 'displays column headers'
      When call validation_section "Test Section"
      The output should include "Check"
      The output should include "Status"
    End
  End

  Describe 'validate_url function'
    It 'is defined'
      When call type validate_url
      The status should be success
      The output should include "function"
    End

    It 'returns 1 for empty URL'
      When call validate_url ""
      The status should equal 1
    End

    It 'returns 0 for special xkcd scheme'
      When call validate_url "xkcd:random"
      The status should equal 0
    End
  End

  Describe 'validate_sitemap function'
    It 'is defined'
      When call type validate_sitemap
      The status should be success
      The output should include "function"
    End

    It 'returns 1 for empty URL'
      When call validate_sitemap ""
      The status should equal 1
    End
  End

  Describe 'validate_api_key function'
    It 'is defined'
      When call type validate_api_key
      The status should be success
      The output should include "function"
    End

    It 'returns 1 for empty key'
      When call validate_api_key "weather" ""
      The status should equal 1
    End

    It 'returns 1 for unknown API type'
      When call validate_api_key "unknown_api" "somekey"
      The status should equal 1
    End
  End

  Describe 'validate_script_permissions function'
    It 'is defined'
      When call type validate_script_permissions
      The status should be success
      The output should include "function"
    End

    It 'returns 1 for non-existent file'
      When call validate_script_permissions "/nonexistent/path/script.sh"
      The status should equal 1
    End

    It 'returns 0 for executable file'
      # goodmorning.sh should be executable
      When call validate_script_permissions "$PWD/goodmorning.sh"
      The status should equal 0
    End
  End

  Describe 'validate_json_file function'
    It 'is defined'
      When call type validate_json_file
      The status should be success
      The output should include "function"
    End

    It 'returns 1 for non-existent file'
      When call validate_json_file "/nonexistent/file.json"
      The status should equal 1
    End

    It 'returns 0 for valid JSON file'
      When call validate_json_file "$PWD/data/learning-sources.json"
      The status should equal 0
    End
  End

  Describe 'validate_dependency function'
    It 'is defined'
      When call type validate_dependency
      The status should be success
      The output should include "function"
    End

    It 'returns 0 for installed command'
      When call validate_dependency "ls"
      The status should equal 0
    End

    It 'returns 1 for non-existent command'
      When call validate_dependency "nonexistent_command_xyz"
      The status should equal 1
    End
  End

  Describe 'validate_dependencies function'
    It 'is defined'
      When call type validate_dependencies
      The status should be success
      The output should include "function"
    End

    It 'returns 0 when all dependencies are installed'
      When call validate_dependencies "ls" "cat" "echo"
      The status should equal 0
    End

    It 'returns 1 and lists missing when some are missing'
      When call validate_dependencies "ls" "nonexistent_xyz"
      The status should equal 1
      The output should include "nonexistent_xyz"
    End
  End

  Describe 'validate_file_exists function'
    It 'is defined'
      When call type validate_file_exists
      The status should be success
      The output should include "function"
    End

    It 'returns 0 for existing file'
      When call validate_file_exists "$PWD/goodmorning.sh"
      The status should equal 0
    End

    It 'returns 1 for non-existent file'
      When call validate_file_exists "/nonexistent/file.txt"
      The status should equal 1
    End
  End

  Describe 'validate_directory_exists function'
    It 'is defined'
      When call type validate_directory_exists
      The status should be success
      The output should include "function"
    End

    It 'returns 0 for existing directory'
      When call validate_directory_exists "$PWD/lib"
      The status should equal 0
    End

    It 'returns 1 for non-existent directory'
      When call validate_directory_exists "/nonexistent/directory"
      The status should equal 1
    End
  End

  Describe 'validate_directory_writable function'
    It 'is defined'
      When call type validate_directory_writable
      The status should be success
      The output should include "function"
    End

    It 'returns 0 for writable directory'
      When call validate_directory_writable "/tmp"
      The status should equal 0
    End

    It 'returns 1 for non-existent directory'
      When call validate_directory_writable "/nonexistent/directory"
      The status should equal 1
    End
  End
End
