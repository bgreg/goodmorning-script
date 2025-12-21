#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'lib/app/colors.sh - Color System'
  Include lib/app/colors.sh

  Describe 'ANSI escape sequences'
    It 'defines ESC_SEQ'
      The variable ESC_SEQ should equal "\x1b["
    End

    It 'defines COLOR_RESET'
      The variable COLOR_RESET should include "39;49;00m"
    End

    It 'defines COLOR_RED'
      The variable COLOR_RED should include "31;01m"
    End

    It 'defines COLOR_GREEN'
      The variable COLOR_GREEN should include "32;01m"
    End

    It 'defines COLOR_YELLOW'
      The variable COLOR_YELLOW should include "33;01m"
    End

    It 'defines COLOR_BLUE'
      The variable COLOR_BLUE should include "34;01m"
    End

    It 'defines COLOR_MAGENTA'
      The variable COLOR_MAGENTA should include "35;01m"
    End

    It 'defines COLOR_CYAN'
      The variable COLOR_CYAN should include "36;01m"
    End

    It 'defines COLOR_GRAY'
      The variable COLOR_GRAY should include "90m"
    End
  End

  Describe 'Color helper functions'
    Describe 'echo_red'
      It 'outputs text in red'
        When call echo_red "test message"
        The output should include "test message"
        The output should include "31;01m"
      End

      It 'handles multiple arguments'
        When call echo_red "hello" "world"
        The output should include "hello world"
      End
    End

    Describe 'echo_green'
      It 'outputs text in green'
        When call echo_green "success"
        The output should include "success"
        The output should include "32;01m"
      End
    End

    Describe 'echo_yellow'
      It 'outputs text in yellow'
        When call echo_yellow "warning"
        The output should include "warning"
        The output should include "33;01m"
      End
    End

    Describe 'echo_blue'
      It 'outputs text in blue'
        When call echo_blue "info"
        The output should include "info"
        The output should include "34;01m"
      End
    End

    Describe 'echo_magenta'
      It 'outputs text in magenta'
        When call echo_magenta "highlight"
        The output should include "highlight"
        The output should include "35;01m"
      End
    End

    Describe 'echo_cyan'
      It 'outputs text in cyan'
        When call echo_cyan "note"
        The output should include "note"
        The output should include "36;01m"
      End
    End

    Describe 'echo_gray'
      It 'outputs text in gray'
        When call echo_gray "muted"
        The output should include "muted"
        The output should include "90m"
      End
    End
  End

  Describe 'Color reset'
    It 'resets colors after each helper function'
      When call echo_red "test"
      The output should include "39;49;00m"
    End

    It 'does not bleed colors to next line'
      result=$(echo_green "line1"; echo "line2")
      When call printf '%s' "$result"
      The output should include "line2"
    End
  End
End
