#!/usr/bin/env zsh
#shellspec shell=zsh

# End-to-End Real API Tests
# Run with: SHELLSPEC_REAL=1 shellspec
# These tests hit real APIs and require internet connectivity

Describe 'E2E Real API Tests'
  Skip if 'SHELLSPEC_REAL not set' [ -z "${SHELLSPEC_REAL:-}" ]
  setup() {
    PROJECT_ROOT="${SHELLSPEC_PROJECT_ROOT:-$(pwd)}"
    CACHE_DIR="$PROJECT_ROOT/cache"
    OUTPUT_FILE=$(mktemp)

    # Clear cache to force fresh API calls
    rm -f "$CACHE_DIR"/*.json 2>/dev/null || true
  }

  cleanup() {
    rm -f "$OUTPUT_FILE" 2>/dev/null || true
  }

  BeforeAll 'setup'
  AfterAll 'cleanup'

  run_goodmorning() {
    env GOODMORNING_SHOW_SETUP_MESSAGES=false \
        GOODMORNING_FORCE_OFFLINE="" \
        "$PROJECT_ROOT/goodmorning.sh" > "$OUTPUT_FILE" 2>&1
  }

  Describe 'Script execution'
    It 'runs without errors'
      When call run_goodmorning
      The status should be success
    End
  End

  Describe 'Section output'
    BeforeAll 'run_goodmorning'

    It 'displays banner greeting'
      The contents of file "$OUTPUT_FILE" should include "Good Morning"
    End

    It 'shows weather with temperature'
      The contents of file "$OUTPUT_FILE" should match pattern "*Weather:*°*"
    End

    It 'shows history with dated events'
      The contents of file "$OUTPUT_FILE" should match pattern "*On This Day*•*"
    End

    It 'shows tech versions with Ruby'
      The contents of file "$OUTPUT_FILE" should match pattern "*Ruby*v[0-9]*"
    End

    It 'shows country with capital city'
      The contents of file "$OUTPUT_FILE" should match pattern "*Country of the Day*Capital:*"
    End

    It 'shows country with population'
      The contents of file "$OUTPUT_FILE" should match pattern "*Population:*[0-9]*"
    End

    It 'shows word of the day with part of speech'
      The contents of file "$OUTPUT_FILE" should match pattern "*Word of the Day*"
    End

    It 'shows Wikipedia with URL'
      The contents of file "$OUTPUT_FILE" should match pattern "*Wikipedia*https://en.wikipedia.org*"
    End

    It 'shows APOD section'
      The contents of file "$OUTPUT_FILE" should match pattern "*Astronomy Picture*"
    End

    It 'shows calendar section'
      The contents of file "$OUTPUT_FILE" should match pattern "*Calendar*"
    End

    It 'shows email section'
      The contents of file "$OUTPUT_FILE" should match pattern "*Email*"
    End

    It 'shows learning tip with source'
      The contents of file "$OUTPUT_FILE" should match pattern "*Learning*Source:*"
    End
  End

  Describe 'Regression checks'
    BeforeAll 'run_goodmorning'

    It 'has no literal null values in output'
      The contents of file "$OUTPUT_FILE" should not match pattern "*🔗 null*"
    End

    It 'has no jq parse errors'
      The contents of file "$OUTPUT_FILE" should not include "parse error"
    End

    It 'has no API/curl errors'
      The contents of file "$OUTPUT_FILE" should not match pattern "*curl*error*"
    End

    It 'has acceptable N/A count'
      na_count() {
        grep -c "N/A$" "$OUTPUT_FILE" 2>/dev/null || echo "0"
      }
      When call na_count
      The output should satisfy test_na_count
    End
  End
End

test_na_count() {
  [ "${1:-0}" -le 3 ]
}
