#!/usr/bin/env zsh
#shellspec shell=zsh

###############################################################################
# Word of the Day Section Tests
#
# Tests for lib/app/sections/word_of_day.sh
###############################################################################

Describe 'lib/app/sections/word_of_day.sh'
  Before 'source_goodmorning'

  Describe 'fetch_word_of_day function'
    It 'is defined'
      When call type fetch_word_of_day
      The status should be success
      The output should include "function"
    End
  End

  Describe 'show_word_of_day function'
    It 'is defined'
      When call type show_word_of_day
      The status should be success
      The output should include "function"
    End
  End
End
