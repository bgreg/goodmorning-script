#!/usr/bin/env zsh

Describe 'lib/app/view_helpers.sh - View Helper Functions'
  Include lib/app/view_helpers.sh

  Describe 'safe_display function'
    It 'returns fallback for null value'
      When call safe_display "null" "N/A"
      The output should equal "N/A"
    End

    It 'returns fallback for empty value'
      When call safe_display "" "N/A"
      The output should equal "N/A"
    End

    It 'returns value when valid'
      When call safe_display "test" "N/A"
      The output should equal "test"
    End

    It 'uses default fallback if not specified'
      When call safe_display ""
      The output should equal "N/A"
    End
  End

  Describe 'truncate_string function'
    It 'truncates long messages with ..'
      When call truncate_string "This is a very long message" 10
      The output should equal "This is a .."
    End

    It 'returns short messages unchanged'
      When call truncate_string "Short" 10
      The output should equal "Short"
    End

    It 'uses default max length of 48'
      local long_string="$(printf '%50s' | tr ' ' 'a')"
      When call truncate_string "$long_string"
      The output should equal "$(printf '%48s' | tr ' ' 'a').."
    End
  End
End
