#!/usr/bin/env zsh

Describe 'lib/app/preflight/environment.sh - Environment Checks'
  Include lib/app/preflight/environment.sh

  Describe 'check_os function'
    It 'passes on macOS'
      When call check_os
      The status should be success
    End

    It 'is defined'
      When call type check_os
      The status should be success
    End
  End

  Describe 'check_shell function'
    It 'passes for zsh'
      When call check_shell
      The status should be success
    End

    It 'detects ZSH_VERSION'
      When call check_shell
      The variable ZSH_VERSION should not be blank
    End
  End

  Describe 'check_terminal function'
    It 'is defined'
      When call type check_terminal
      The status should be success
    End

    It 'detects iTerm2 correctly'
      TERM_PROGRAM="iTerm.app"
      When call check_terminal
      The status should be success
    End
  End

  Describe 'check_directories function'
    It 'validates config directory exists'
      When call check_directories
      The status should be success
    End

    It 'is defined'
      When call type check_directories
      The status should be success
    End
  End

  Describe 'check_permissions function'
    It 'is defined'
      When call type check_permissions
      The status should be success
    End

    It 'validates script directory permissions'
      When call check_permissions
      The status should be success
    End
  End

  Describe 'check_setup_complete function'
    It 'is defined'
      When call type check_setup_complete
      The status should be success
    End

    It 'returns success when GOODMORNING_SETUP_COMPLETE is true'
      GOODMORNING_SETUP_COMPLETE="true"
      When call check_setup_complete
      The status should be success
    End

    It 'returns failure when GOODMORNING_SETUP_COMPLETE is not set'
      unset GOODMORNING_SETUP_COMPLETE
      When call check_setup_complete
      The status should be failure
    End

    It 'returns failure when GOODMORNING_SETUP_COMPLETE is false'
      GOODMORNING_SETUP_COMPLETE="false"
      When call check_setup_complete
      The status should be failure
    End

    It 'returns failure when GOODMORNING_SETUP_COMPLETE is empty'
      GOODMORNING_SETUP_COMPLETE=""
      When call check_setup_complete
      The status should be failure
    End
  End
End
