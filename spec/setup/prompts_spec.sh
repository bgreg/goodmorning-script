#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'setup.sh - Interactive Prompts'
  Include lib/colors.sh

  Describe 'Color helper -n flag support'
    It 'echo_green -n outputs without trailing newline'
      output() { echo_green -n "test"; echo "END"; }
      When call output
      The lines of output should equal 1
    End

    It 'echo_green without -n includes newline'
      When call echo_green "test"
      The output should include "test"
      The lines of output should equal 1
    End

    It 'echo_yellow -n outputs without trailing newline'
      output() { echo_yellow -n "test"; echo "END"; }
      When call output
      The lines of output should equal 1
    End

    It 'echo_cyan -n outputs without trailing newline'
      output() { echo_cyan -n "test"; echo "END"; }
      When call output
      The lines of output should equal 1
    End

    It 'echo_red -n outputs without trailing newline'
      output() { echo_red -n "test"; echo "END"; }
      When call output
      The lines of output should equal 1
    End

    It 'echo_blue -n outputs without trailing newline'
      output() { echo_blue -n "test"; echo "END"; }
      When call output
      The lines of output should equal 1
    End
  End

  Describe 'Prompt behavior simulation'
    It 'prompt text stays on same line as input'
      output() { echo_green -n "Enter value: "; echo "user_typed_this"; }
      When call output
      The output should include "Enter value:"
      The output should include "user_typed_this"
      The lines of output should equal 1
    End

    It 'colored prompt followed by user input on single line'
      output() { echo_yellow -n "Name [default]: "; echo "actual_input"; }
      When call output
      The lines of output should equal 1
    End

    It 'sequential prompts create separate lines'
      output() {
        echo_green -n "First: "; echo "a"
        echo_green -n "Second: "; echo "b"
        echo_green -n "Third: "; echo "c"
      }
      When call output
      The lines of output should equal 3
    End
  End

  Describe 'Color code availability'
    It 'COLOR_GREEN is defined'
      The variable COLOR_GREEN should be defined
    End

    It 'COLOR_RESET is defined'
      The variable COLOR_RESET should be defined
    End

    It 'COLOR_YELLOW is defined'
      The variable COLOR_YELLOW should be defined
    End

    It 'COLOR_RED is defined'
      The variable COLOR_RED should be defined
    End

    It 'COLOR_CYAN is defined'
      The variable COLOR_CYAN should be defined
    End
  End
End
