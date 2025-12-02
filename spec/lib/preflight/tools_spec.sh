#!/usr/bin/env zsh

Describe 'lib/preflight/tools.sh - Tool Checks'
  Include lib/preflight/tools.sh

  Describe 'check_required_tools function'
    It 'is defined'
      When call type check_required_tools
      The status should be success
    End

    It 'finds git'
      When call check_required_tools
      The output should include "git"
      The status should be success
    End

    It 'finds curl'
      When call check_required_tools
      The output should include "curl"
      The status should be success
    End

    It 'finds jq'
      When call check_required_tools
      The output should include "jq"
      The status should be success
    End
  End

  Describe 'check_optional_tools function'
    It 'is defined'
      When call type check_optional_tools
      The status should be success
    End

    It 'checks for gh CLI'
      When call check_optional_tools
      The output should include "gh"
    End

    It 'checks for icalBuddy'
      When call check_optional_tools
      The output should include "icalBuddy"
    End
  End

  Describe 'REQUIRED_TOOLS array'
    It 'is defined'
      The variable REQUIRED_TOOLS should be defined
    End

    It 'includes curl'
      The value "${REQUIRED_TOOLS[curl]}" should equal "1"
    End

    It 'includes git'
      The value "${REQUIRED_TOOLS[git]}" should equal "1"
    End

    It 'includes jq'
      The value "${REQUIRED_TOOLS[jq]}" should equal "1"
    End
  End

  Describe 'OPTIONAL_TOOLS array'
    It 'is defined'
      The variable OPTIONAL_TOOLS should be defined
    End

    It 'describes GitHub features'
      The value "${OPTIONAL_TOOLS[gh]}" should include "GitHub"
    End

    It 'describes Calendar features'
      The value "${OPTIONAL_TOOLS[icalBuddy]}" should include "Calendar"
    End
  End
End
