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

  Describe 'get_country_of_day JSON handling'
    Context 'when API response contains backslash escape sequences'
      setup_escape_mock() {
        fetch_url() {
          local url="$1"
          if [[ "$url" == *"all?fields=name"* ]]; then
            printf '%s\n' '[{"name":{"common":"Testland"}}]'
          else
            printf '%s\n' '[{"name":{"common":"Testland","official":"Republic of Testland"},"flag":"T","capital":["TestCity"],"region":"TestRegion","subregion":"Sub","population":5000000,"area":50000,"flags":{"alt":"Red\nand blue\tstripes"},"languages":{"eng":"English"},"currencies":{"TST":{"name":"Dollar"}}}]'
          fi
        }
        sleep() { :; }
      }

      Before 'setup_escape_mock'

      It 'preserves JSON integrity through jq pipeline'
        When call get_country_of_day
        The status should be success
        The output should include "Testland"
      End
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
