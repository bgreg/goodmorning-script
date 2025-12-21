#!/usr/bin/env zsh
#shellspec shell=zsh

###############################################################################
# Astronomy Picture of the Day Tests
#
# Tests for lib/app/sections/astronomy_picture.sh
###############################################################################

Describe 'lib/app/sections/astronomy_picture.sh'
  Include "$PWD/spec/spec_helper.sh"
  Before 'source_goodmorning'

  Describe 'fetch_apod function'
    It 'is defined'
      When call type fetch_apod
      The status should be success
      The output should include "function"
    End
  End

  Describe '_display_apod_image function'
    It 'is defined'
      When call type _display_apod_image
      The status should be success
      The output should include "function"
    End
  End

  Describe '_generate_apod_url function'
    It 'is defined'
      When call type _generate_apod_url
      The status should be success
      The output should include "function"
    End

    It 'returns provided URL when available'
      When call _generate_apod_url "https://example.com/image.jpg" ""
      The output should equal "https://example.com/image.jpg"
    End

    It 'generates date-based URL when no URL but date provided'
      When call _generate_apod_url "" "2024-12-15"
      The output should include "apod.nasa.gov"
      The output should include "241215"
    End

    It 'returns default URL when neither URL nor date provided'
      When call _generate_apod_url "" ""
      The output should equal "https://apod.nasa.gov/apod/astropix.html"
    End
  End

  Describe 'fetch_apod function'
    It 'uses GOODMORNING_NASA_API_KEY when provided'
      When call grep 'GOODMORNING_NASA_API_KEY' "$PROJECT_ROOT/lib/app/sections/astronomy_picture.sh"
      The output should include "GOODMORNING_NASA_API_KEY"
    End

    It 'falls back to DEMO_KEY'
      When call grep 'DEMO_KEY' "$PROJECT_ROOT/lib/app/sections/astronomy_picture.sh"
      The output should include "DEMO_KEY"
    End
  End

  Describe 'show_apod function'
    It 'is defined'
      When call type show_apod
      The status should be success
      The output should include "function"
    End
  End
End
