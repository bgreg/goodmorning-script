#!/usr/bin/env zsh
#shellspec shell=zsh

###############################################################################
# Country of the Day Tests
#
# Tests for lib/app/sections/country_of_day.sh
###############################################################################

Describe 'lib/app/sections/country_of_day.sh'
  Include "$PWD/spec/spec_helper.sh"
  Before 'source_goodmorning'

  Describe 'get_country_of_day function'
    It 'is defined'
      When call type get_country_of_day
      The status should be success
      The output should include "function"
    End

    It 'returns country data as JSON'
      # Mock curl response
      curl() {
        echo '[{"name":{"common":"Japan"},"capital":["Tokyo"],"population":125800000,"region":"Asia","flags":{"png":"https://example.com/flag.png"}}]'
      }
      When call get_country_of_day
      The output should include "Japan"
    End
  End

  Describe 'show_country_of_day function'
    It 'is defined'
      When call type show_country_of_day
      The status should be success
      The output should include "function"
    End
  End
End
