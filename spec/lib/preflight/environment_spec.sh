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
End
