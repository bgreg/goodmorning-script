#!/usr/bin/env zsh
#shellspec shell=zsh

###############################################################################
# Wikipedia Featured Article Tests
#
# Tests for lib/app/sections/wikipedia_featured.sh
###############################################################################

Describe 'lib/app/sections/wikipedia_featured.sh'
  Include "$PWD/spec/spec_helper.sh"
  Before 'source_goodmorning'

  Describe 'fetch_wikipedia_featured function'
    It 'is defined'
      When call type fetch_wikipedia_featured
      The status should be success
      The output should include "function"
    End
  End

  Describe 'show_wikipedia_featured function'
    It 'is defined'
      When call type show_wikipedia_featured
      The status should be success
      The output should include "function"
    End
  End
End
