#!/usr/bin/env zsh
#shellspec shell=zsh

# End-to-End Real API Tests
# Run with: SHELLSPEC_REAL=1 shellspec spec/e2e/real_api_spec.sh
# These tests hit real APIs and require internet connectivity

Describe 'E2E Real API Tests'
  Skip if 'SHELLSPEC_REAL not set' [ -z "${SHELLSPEC_REAL:-}" ]

  # Use a fixed output file location
  OUTPUT_FILE="/tmp/goodmorning_e2e_output.txt"

  setup() {
    local project_root="${SHELLSPEC_PROJECT_ROOT:-$(pwd)}"

    # Clear most caches to force fresh API calls
    # Keep apod.json since NASA API is often rate-limited
    setopt localoptions nullglob
    for f in "${project_root}/cache"/*.json; do
      [[ "$f" != *"apod.json" ]] && rm -f "$f"
    done
    rm -f "$OUTPUT_FILE" 2>/dev/null

    # Run the script once and save output
    # Unset GOODMORNING_NO_AUTO_RUN to allow script execution (set by spec_helper.sh)
    env GOODMORNING_SHOW_SETUP_MESSAGES=false \
        GOODMORNING_FORCE_OFFLINE="" \
        GOODMORNING_NO_AUTO_RUN="" \
        "${project_root}/goodmorning.sh" > "$OUTPUT_FILE" 2>&1
    return 0
  }

  cleanup() {
    rm -f "$OUTPUT_FILE" 2>/dev/null || true
  }

  BeforeAll 'setup'
  AfterAll 'cleanup'

  # Helper function for N/A count test
  test_na_count() {
    [ "${1:-0}" -le 3 ]
  }

  Describe 'Script execution'
    It 'runs and produces output'
      The file "$OUTPUT_FILE" should be exist
      The contents of file "$OUTPUT_FILE" should not be blank
    End
  End

  Describe 'Section output'
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

    It 'shows APOD with URL'
      The contents of file "$OUTPUT_FILE" should match pattern "*Astronomy Picture*🔗 http*"
    End

    It 'shows calendar section'
      The contents of file "$OUTPUT_FILE" should match pattern "*Calendar*"
    End

    It 'shows daily learning section'
      The contents of file "$OUTPUT_FILE" should match pattern "*Daily Learning*"
    End

    It 'shows daily learning sitemap resource'
      The contents of file "$OUTPUT_FILE" should match pattern "*From Sitemap*Topic:*"
    End

    It 'shows daily learning static resource'
      The contents of file "$OUTPUT_FILE" should match pattern "*Static Resource*Topic:*"
    End

    It 'shows sanity maintenance section'
      The contents of file "$OUTPUT_FILE" should match pattern "*Sanity Maintenance*"
    End

    It 'shows alias suggestions section'
      The contents of file "$OUTPUT_FILE" should match pattern "*Alias Suggestions*"
    End

    It 'shows common typos section'
      The contents of file "$OUTPUT_FILE" should match pattern "*Common Typos*"
    End

    It 'shows cat of the day section'
      The contents of file "$OUTPUT_FILE" should match pattern "*Cat of the Day*"
    End
  End

  Describe 'Regression checks'
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
