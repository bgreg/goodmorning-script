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
    shift # Skip the message parameter
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
    shift # Skip message parameter
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
    shift # Skip message parameter
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

Describe 'show_github_notifications with GITHUB_REPO'
setup_gh_mock() {
  GH_CALLS_FILE=$(mktemp)
  command_exists() { return 0; }
  gh() {
    if [[ "$1" == "auth" ]]; then
      return 0
    fi
    echo "$*" >>"$GH_CALLS_FILE"
    echo "0"
  }
  fetch_with_spinner() {
    shift
    "$@"
  }
}

Before 'setup_gh_mock'

It 'uses repo-scoped endpoint when GITHUB_REPO is set'
GITHUB_REPO="acme/webapp"
When call show_github_notifications
The output should be present
The contents of file "$GH_CALLS_FILE" should include "/repos/acme/webapp/notifications"
End

It 'uses global endpoint when GITHUB_REPO is unset'
GITHUB_REPO=""
When call show_github_notifications
The output should be present
The contents of file "$GH_CALLS_FILE" should include "api notifications"
The contents of file "$GH_CALLS_FILE" should not include "/repos/"
End
End

Describe 'show_learning_tips function'
It 'is defined'
When call type show_learning_tips
The status should be success
The output should not be blank
End
End

Describe '_validate_author_email function'
It 'accepts user@example.com'
When call _validate_author_email "user@example.com"
The status should be success
End

It 'accepts first.last+tag@co.uk'
When call _validate_author_email "first.last+tag@co.uk"
The status should be success
End

It 'rejects email with no at sign'
When call _validate_author_email "userexample.com"
The status should be failure
End

It 'rejects empty string'
When call _validate_author_email ""
The status should be failure
End

It 'rejects email with no domain after at sign'
When call _validate_author_email "user@"
The status should be failure
End
End

Describe '_build_learning_prompt function'
It 'personalized type includes context text'
When call _build_learning_prompt "Added Rails API endpoints" "personalized"
The output should include "Added Rails API endpoints"
End

It 'personalized type mentions recent development work'
When call _build_learning_prompt "some context" "personalized"
The output should include "recent development work"
End

It 'personalized type includes Source: requirement'
When call _build_learning_prompt "some context" "personalized"
The output should include "Source:"
End

It 'general type does not include context text'
When call _build_learning_prompt "Added Rails API endpoints" "general"
The output should not include "Added Rails API endpoints"
End

It 'general type includes Source: requirement'
When call _build_learning_prompt "" "general"
The output should include "Source:"
End
End

Describe '_show_claude_install_message function'
It 'outputs install message when SHOW_SETUP_MESSAGES is true'
SHOW_SETUP_MESSAGES="true"
When call _show_claude_install_message
The output should include "Install Claude Code"
End

It 'outputs nothing when SHOW_SETUP_MESSAGES is false'
SHOW_SETUP_MESSAGES="false"
GOODMORNING_SHOW_SETUP_MESSAGES="false"
When call _show_claude_install_message
The output should be blank
End
End

Describe '_get_repo_commits function'
setup_temp_repo() {
  TEST_REPO_DIR=$(mktemp -d)
  git -C "$TEST_REPO_DIR" init --quiet
  git -C "$TEST_REPO_DIR" config user.email "test@example.com"
  git -C "$TEST_REPO_DIR" config user.name "Test User"
  touch "$TEST_REPO_DIR/file.txt"
  git -C "$TEST_REPO_DIR" add .
  git -C "$TEST_REPO_DIR" commit --quiet -m "Initial test commit"
  export GIT_LOOKBACK_DAYS=30
  export MAX_COMMITS_PER_REPO=10
  export LOG_FILE="/dev/null"
}

cleanup_temp_repo() {
  [ -d "$TEST_REPO_DIR" ] && rm -rf "$TEST_REPO_DIR"
}

Before 'setup_temp_repo'
After 'cleanup_temp_repo'

It 'returns commits from a valid repo'
When call _get_repo_commits "$TEST_REPO_DIR/.git"
The status should be success
The output should include "Initial test commit"
End

It 'returns failure when gitdir does not exist'
When call _get_repo_commits "/nonexistent/path/.git"
The status should be failure
End
End

Describe '_gather_git_context function'
It 'returns blank when PROJECT_DIRS is empty'
PROJECT_DIRS=""
LOG_FILE="/dev/null"
GIT_SCAN_DEPTH=2
GIT_SCAN_TIMEOUT=5
MAX_REPOS_TO_SCAN=5
When call _gather_git_context
The output should be blank
End
End

Describe '_generate_and_display_tip function'
setup_fetch_mock() {
  fetch_with_spinner() {
    shift
    echo "Use meaningful variable names for clarity."
  }
  LOG_FILE="/dev/null"
}

Before 'setup_fetch_mock'

It 'displays tip when fetch_with_spinner returns content'
When call _generate_and_display_tip "some context" "personalized"
The output should include "meaningful variable names"
End

It 'displays personalized fallback when fetch returns empty'
fetch_with_spinner() { echo ""; }
When call _generate_and_display_tip "some context" "personalized"
The output should include "Unable to generate personalized tip"
End

It 'displays general fallback when fetch returns empty for general type'
fetch_with_spinner() { echo ""; }
When call _generate_and_display_tip "" "general"
The output should include "Claude learning tips unavailable"
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
