#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'E2E Real API Tests'

OUTPUT_FILE="/tmp/goodmorning_e2e_output.txt"

setup() {
  local project_root="${SHELLSPEC_PROJECT_ROOT:-$(pwd)}"
  rm -f "$OUTPUT_FILE" 2>/dev/null

  local xdg_data="/tmp/goodmorning_e2e_xdg_$$"
  mkdir -p "$xdg_data/zsh"
  printf "2026-04-01 09:15: foobar\n2026-04-02 10:30: foobar\n2026-04-02 14:00: bazzle\n" >"$xdg_data/zsh/command-not-found.log"

  local env_args=(
    GOODMORNING_NO_AUTO_RUN=""
    GOODMORNING_SHOW_SETUP_MESSAGES=false
    GOODMORNING_SETUP_COMPLETE=true
    GOODMORNING_WEATHER_LOCATION=TestCity
    GOODMORNING_OPEN_LINKS=false
    GOODMORNING_RUN_UPDATES=false
    GOODMORNING_SHOW_JIRA_TICKETS=false
    XDG_DATA_HOME="$xdg_data"
    HISTFILE=/tmp/goodmorning_e2e_fake_history
  )

  touch /tmp/goodmorning_e2e_fake_history

  if [ -z "${SHELLSPEC_REAL:-}" ]; then
    env_args+=(PATH="${project_root}/spec/support/bin:${PATH}")
    env_args+=(GOODMORNING_FORCE_OFFLINE="")
  else
    env_args+=(GOODMORNING_FORCE_OFFLINE="")
  fi

  local config_dir="/tmp/goodmorning_e2e_config_$$"
  mkdir -p "$config_dir/logs"
  env_args+=(GOODMORNING_CONFIG_DIR="$config_dir")

  cp "${project_root}/data/learning-sources.json" "$config_dir/" 2>/dev/null
  cp "${project_root}/data/sanity-maintenance-sources.json" "$config_dir/" 2>/dev/null

  env "${env_args[@]}" "${project_root}/goodmorning.sh" >"$OUTPUT_FILE" 2>&1
  return 0
}

cleanup() {
  rm -f "$OUTPUT_FILE" 2>/dev/null || true
  rm -f /tmp/goodmorning_e2e_fake_history 2>/dev/null || true
  rm -rf /tmp/goodmorning_e2e_config_$$ 2>/dev/null || true
  rm -rf /tmp/goodmorning_e2e_xdg_$$ 2>/dev/null || true
}

BeforeAll 'setup'
AfterAll 'cleanup'

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

It 'shows word of the day section header'
The contents of file "$OUTPUT_FILE" should match pattern "*Word of the Day*"
End

It 'shows word of the day with actual word (not empty)'
The contents of file "$OUTPUT_FILE" should match pattern "*📖 *"
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

It 'shows daily learning section'
The contents of file "$OUTPUT_FILE" should match pattern "*Daily Learning*"
End

It 'shows sanity maintenance section'
The contents of file "$OUTPUT_FILE" should match pattern "*Sanity Maintenance*"
End

It 'shows alias suggestions section'
The contents of file "$OUTPUT_FILE" should match pattern "*Alias Suggestions*"
End

It 'shows cat of the day section'
The contents of file "$OUTPUT_FILE" should match pattern "*Cat of the Day*"
End

It 'shows calendar section'
The contents of file "$OUTPUT_FILE" should match pattern "*Calendar*"
End

It 'shows reminders section'
The contents of file "$OUTPUT_FILE" should match pattern "*Reminders*"
End

It 'shows system info section'
The contents of file "$OUTPUT_FILE" should match pattern "*System Info*"
End

It 'shows command not found section'
The contents of file "$OUTPUT_FILE" should match pattern "*Commands Not Found*"
End

It 'shows learning tips section'
The contents of file "$OUTPUT_FILE" should match pattern "*Learning Tip*"
End

It 'shows GitHub notifications section'
The contents of file "$OUTPUT_FILE" should match pattern "*GitHub Notifications*"
End

It 'shows GitHub PR section'
The contents of file "$OUTPUT_FILE" should match pattern "*GitHub PR*"
End

It 'shows GitHub Issues section'
The contents of file "$OUTPUT_FILE" should match pattern "*GitHub Issues*"
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

It 'has no sed command errors'
The contents of file "$OUTPUT_FILE" should not include "sed:"
The contents of file "$OUTPUT_FILE" should not include "invalid command"
End

It 'has no awk errors'
The contents of file "$OUTPUT_FILE" should not include "awk:"
End

It 'has no zsh errors'
The contents of file "$OUTPUT_FILE" should not include "command not found"
The contents of file "$OUTPUT_FILE" should not include "no such file"
End

It 'has no PATH corruption errors'
The contents of file "$OUTPUT_FILE" should not match pattern "*ls:*not found*"
The contents of file "$OUTPUT_FILE" should not match pattern "*jq:*not found*"
The contents of file "$OUTPUT_FILE" should not match pattern "*curl:*not found*"
End

It 'has acceptable N/A count'
na_count() {
  grep -c "N/A$" "$OUTPUT_FILE" 2>/dev/null || echo "0"
}
When call na_count
The output should satisfy test_na_count
End

It 'does not show generic error states'
error_patterns() {
  grep -cE '(n/a|N/A|undefined|null)' "$OUTPUT_FILE" 2>/dev/null || echo "0"
}
When call error_patterns
The output should satisfy test_na_count
End
End
End
