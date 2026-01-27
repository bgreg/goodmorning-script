#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'lib/app/display.sh - Display Functions'
  Before 'source_goodmorning'

  Describe 'show_banner function'
    It 'is defined'
      When call type show_banner
      The status should be success
      The output should not be blank
    End

    It 'checks for BANNER_FILE'
      When call grep 'BANNER_FILE' "$PROJECT_ROOT/lib/app/display.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe 'show_reminders function'
    It 'is defined'
      When call type show_reminders
      The status should be success
      The output should not be blank
    End

    It 'uses correct AppleScript path for reminder count'
      When call grep 'lib/app/apple_scripts/count_reminders.scpt' "$PROJECT_ROOT/lib/app/display.sh"
      The status should be success
      The output should not be blank
    End

    It 'validates reminder count is numeric'
      When call grep '\[\[.*reminder_count.*\^\[0-9\]' "$PROJECT_ROOT/lib/app/display.sh"
      The status should be success
      The output should not be blank
    End

    It 'respects MAX_REMINDERS limit'
      When call grep 'MAX_REMINDERS' "$PROJECT_ROOT/lib/app/display.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe 'show_weather function'
    It 'is defined'
      When call type show_weather
      The status should be success
      The output should not be blank
    End

    # Integration tests with mocked fetch_with_spinner
    It 'returns early when GOODMORNING_WEATHER_LOCATION is not set'
      GOODMORNING_WEATHER_LOCATION=""
      SHOW_SETUP_MESSAGES="true"
      When call show_weather
      The status should be success
      The output should include "Set GOODMORNING_WEATHER_LOCATION"
    End

    Context 'with mocked fetch_with_spinner'
      setup_basic_mock() {
        fetch_with_spinner() {
          shift  # Skip the message parameter
          # Verify we're being called with curl command
          if [ "$1" != "curl" ]; then
            echo "Expected curl command, got: $1" >&2
            return 1
          fi
          echo "$MOCK_WEATHER_RESPONSE"
        }
      }

      Before 'setup_basic_mock'

      It 'successfully fetches weather when location is set'
        GOODMORNING_WEATHER_LOCATION="San_Francisco"
        MOCK_WEATHER_RESPONSE="San Francisco ☀️  +72°F"
        When call show_weather
        The status should be success
        The output should include "☀️"
        The output should include "+72°F"
      End

      It 'handles not found response from API'
        GOODMORNING_WEATHER_LOCATION="InvalidCity123"
        MOCK_WEATHER_RESPONSE="not found: InvalidCity123"
        When call show_weather
        The status should be success
        The output should include "Weather unavailable for"
        The output should include "InvalidCity123"
      End

      It 'handles empty response from API'
        GOODMORNING_WEATHER_LOCATION="TestCity"
        MOCK_WEATHER_RESPONSE=""
        When call show_weather
        The status should be success
        The output should include "Weather unavailable for"
        The output should include "TestCity"
      End
    End

    Context 'URL and parameter validation'
      It 'uses location in wttr.in URL construction'
        setup_url_check() {
          fetch_with_spinner() {
            shift  # Skip message parameter
            # Verify URL contains location
            for arg in "$@"; do
              if [[ "$arg" == *"wttr.in/New_York"* ]]; then
                echo "New York 🌧️  +65°F"
                return 0
              fi
            done
            echo "URL validation failed" >&2
            return 1
          }
        }
        
        setup_url_check
        GOODMORNING_WEATHER_LOCATION="New_York"
        When call show_weather
        The status should be success
        The output should include "🌧️"
      End

      It 'passes correct parameters to curl command'
        setup_param_check() {
          fetch_with_spinner() {
            shift  # Skip message parameter
            # Check for expected curl command and flags
            local has_curl=false
            local has_silent=false
            local has_timeout=false
            local has_url=false
            
            for arg in "$@"; do
              [[ "$arg" == "curl" ]] && has_curl=true
              [[ "$arg" == "-s" ]] && has_silent=true
              [[ "$arg" == "--max-time" ]] && has_timeout=true
              [[ "$arg" == *"wttr.in/Boston"* ]] && has_url=true
            done
            
            if $has_curl && $has_silent && $has_timeout && $has_url; then
              echo "Boston ⛅  +68°F"
              return 0
            fi
            echo "Missing expected curl parameters" >&2
            return 1
          }
        }
        
        setup_param_check
        GOODMORNING_WEATHER_LOCATION="Boston"
        When call show_weather
        The status should be success
        The output should include "⛅"
      End
    End

    Context 'location validation'
      setup_validation_mock() {
        fetch_with_spinner() {
          shift
          echo "MockCity ☀️  +70°F"
        }
      }

      Before 'setup_validation_mock'

      It 'accepts comma-separated city,state format'
        GOODMORNING_WEATHER_LOCATION="chico,ca"
        When call show_weather
        The status should be success
        The output should include "☀️"
      End

      It 'accepts coordinate format with period and comma'
        GOODMORNING_WEATHER_LOCATION="48.85,2.35"
        When call show_weather
        The status should be success
        The output should include "☀️"
      End

      It 'accepts plus for multi-word cities'
        GOODMORNING_WEATHER_LOCATION="New+York"
        When call show_weather
        The status should be success
        The output should include "☀️"
      End

      It 'accepts tilde for named locations'
        GOODMORNING_WEATHER_LOCATION="~Eiffel+Tower"
        When call show_weather
        The status should be success
        The output should include "☀️"
      End

      It 'rejects spaces'
        GOODMORNING_WEATHER_LOCATION="New York"
        When call show_weather
        The status should be failure
        The output should include "Weather"
        The stderr should include "Invalid weather location"
      End

      It 'rejects backticks'
        GOODMORNING_WEATHER_LOCATION='city`cmd`'
        When call show_weather
        The status should be failure
        The output should include "Weather"
        The stderr should include "Invalid weather location"
      End

    End
  End

  Describe 'show_history function'
    It 'is defined'
      When call type show_history
      The status should be success
      The output should not be blank
    End

    It 'respects MAX_HISTORY_EVENTS limit'
      When call grep 'MAX_HISTORY_EVENTS' "$PROJECT_ROOT/lib/app/display.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe 'show_calendar function'
    It 'is defined'
      When call type show_calendar
      The status should be success
      The output should not be blank
    End

    It 'supports icalBuddy integration'
      When call grep 'icalBuddy' "$PROJECT_ROOT/lib/app/display.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe 'show_learning_tips function'
    It 'is defined'
      When call type show_learning_tips
      The status should be success
      The output should not be blank
    End
  End

  Describe 'show_alias_suggestions function'
    It 'is defined'
      When call type show_alias_suggestions
      The status should be success
      The output should not be blank
    End

    It 'reads from shell history'
      When call grep 'HISTFILE' "$PROJECT_ROOT/lib/app/sections/alias_suggestions.sh"
      The status should be success
      The output should not be blank
    End

    It 'checks for existing aliases'
      When call grep 'alias.*grep' "$PROJECT_ROOT/lib/app/sections/alias_suggestions.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe 'show_cat_of_day function'
    It 'is defined'
      When call type show_cat_of_day
      The status should be success
      The output should not be blank
    End

    It 'uses Cat API'
      When call grep 'thecatapi.com' "$PROJECT_ROOT/lib/app/sections/cat_of_day.sh"
      The status should be success
      The output should not be blank
    End

    It 'supports iTerm2 image display'
      When call grep 'display_image_iterm' "$PROJECT_ROOT/lib/app/core.sh"
      The status should be success
      The output should not be blank
    End
  End
End
