#!/usr/bin/env zsh
#shellspec shell=zsh

###############################################################################
# Doctor Mode Tests
#
# Tests for lib/setup/doctor.sh
###############################################################################

Describe 'lib/setup/doctor.sh'
  Include "$PWD/spec/spec_helper.sh"

  setup() {
    source "$PWD/lib/app/colors.sh"
    source "$PWD/lib/app/view_helpers.sh"
    source "$PWD/lib/setup/validation_helpers.sh"
    source "$PWD/lib/setup/doctor.sh"
    LOG_FILE="/dev/null"
    SCRIPT_DIR="$PWD"
    CONFIG_DIR="/tmp/goodmorning_test_$$"
    mkdir -p "$CONFIG_DIR"
  }

  cleanup() {
    rm -rf "/tmp/goodmorning_test_$$"
  }

  Before 'setup'
  After 'cleanup'

  Describe 'run_doctor function'
    It 'is defined'
      When call type run_doctor
      The status should be success
      The output should include "function"
    End
  End

  Describe 'doctor_check_system_environment function'
    It 'is defined'
      When call type doctor_check_system_environment
      The status should be success
      The output should include "function"
    End

    It 'produces output when called'
      When call doctor_check_system_environment
      The output should be present
    End
  End

  Describe 'doctor_check_terminal_features function'
    It 'is defined'
      When call type doctor_check_terminal_features
      The status should be success
      The output should include "function"
    End
  End

  Describe 'doctor_check_network function'
    It 'is defined'
      When call type doctor_check_network
      The status should be success
      The output should include "function"
    End
  End

  Describe 'doctor_check_macos_services function'
    It 'is defined'
      When call type doctor_check_macos_services
      The status should be success
      The output should include "function"
    End
  End

  Describe 'doctor_check_configured_paths function'
    It 'is defined'
      When call type doctor_check_configured_paths
      The status should be success
      The output should include "function"
    End
  End

  Describe 'doctor_check_api_keys function'
    It 'is defined'
      When call type doctor_check_api_keys
      The status should be success
      The output should include "function"
    End
  End

  Describe 'doctor_check_symlinks function'
    It 'is defined'
      When call type doctor_check_symlinks
      The status should be success
      The output should include "function"
    End
  End

  Describe 'doctor_check_dependencies function'
    It 'is defined'
      When call type doctor_check_dependencies
      The status should be success
      The output should include "function"
    End

    It 'checks for required tools'
      When call doctor_check_dependencies
      The output should include "curl"
    End
  End

  Describe 'doctor_check_config function'
    It 'is defined'
      When call type doctor_check_config
      The status should be success
      The output should include "function"
    End
  End

  Describe 'doctor_check_permissions function'
    It 'is defined'
      When call type doctor_check_permissions
      The status should be success
      The output should include "function"
    End
  End

  Describe 'doctor_check_json_files function'
    It 'is defined'
      When call type doctor_check_json_files
      The status should be success
      The output should include "function"
    End
  End

  Describe 'doctor_check_urls function'
    It 'is defined'
      When call type doctor_check_urls
      The status should be success
      The output should include "function"
    End
  End

  Describe 'doctor_print_summary function'
    It 'is defined'
      When call type doctor_print_summary
      The status should be success
      The output should include "function"
    End

    It 'displays validation counts'
      VALIDATION_PASSED=5
      VALIDATION_FAILED=2
      VALIDATION_WARNED=1
      When call doctor_print_summary
      The output should include "5"
    End
  End
End
