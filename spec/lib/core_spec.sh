#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'lib/app/core.sh - Core Utilities'
Before 'source_goodmorning'

Describe 'cleanup_background_processes function'
It 'is defined'
When call type cleanup_background_processes
The status should be success
The output should not be blank
End

It 'handles empty BACKGROUND_PIDS array'
BACKGROUND_PIDS=()
When call cleanup_background_processes
The status should be success
End
End

Describe 'safe_source function'
setup() {
  TEST_DIR=$(mktemp -d)
  VALID_FILE="$TEST_DIR/valid.sh"
  MISSING_FILE="$TEST_DIR/missing.sh"
  WORLD_WRITABLE="$TEST_DIR/writable.sh"

  # Valid file
  echo '#!/usr/bin/env zsh' >"$VALID_FILE"
  echo 'TEST_VAR="loaded"' >>"$VALID_FILE"
  chmod 644 "$VALID_FILE"

  # World-writable file (security risk)
  echo '#!/usr/bin/env zsh' >"$WORLD_WRITABLE"
  chmod 666 "$WORLD_WRITABLE"
}

cleanup() {
  [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

Before 'setup'
After 'cleanup'

It 'is defined'
When call type safe_source
The status should be success
The output should not be blank
End

It 'rejects missing files'
When call safe_source "$MISSING_FILE"
The status should be failure
The stderr should not be blank
End

It 'rejects world-writable files'
When call safe_source "$WORLD_WRITABLE"
The status should be failure
The stderr should include "Security"
End

It 'successfully sources valid files'
When call safe_source "$VALID_FILE"
The status should be success
End

It 'loads variables from sourced file'
safe_source "$VALID_FILE" >/dev/null 2>&1
The variable TEST_VAR should equal "loaded"
End
End

Describe 'command_exists function'
It 'is defined'
When call type command_exists
The status should be success
The output should not be blank
End

It 'returns success for existing commands'
When call command_exists echo
The status should be success
End

It 'returns failure for non-existent commands'
When call command_exists nonexistent_command_xyz
The status should be failure
End
End

Describe 'show_setup_message function'
It 'is defined'
When call type show_setup_message
The status should be success
The output should not be blank
End

It 'respects GOODMORNING_SHOW_SETUP_MESSAGES=false'
%preserve GOODMORNING_SHOW_SETUP_MESSAGES:false
When call show_setup_message "test message"
The output should be blank
End
End

Describe 'print_section function'
It 'is defined'
When call type print_section
The status should be success
The output should not be blank
End

It 'formats section headers'
When call print_section "Test Section"
The output should include "Test Section"
End
End

Describe 'is_iterm function'
It 'returns success when TERM_PROGRAM is iTerm.app'
TERM_PROGRAM="iTerm.app"
LC_TERMINAL=""
When call is_iterm
The status should be success
End

It 'returns success when LC_TERMINAL is iTerm2'
TERM_PROGRAM=""
LC_TERMINAL="iTerm2"
When call is_iterm
The status should be success
End

It 'returns failure when neither variable matches'
TERM_PROGRAM="Apple_Terminal"
LC_TERMINAL=""
When call is_iterm
The status should be failure
End
End

Describe 'iterm_mark function'
It 'is defined'
When call type iterm_mark
The status should be success
The output should not be blank
End

It 'succeeds when not in iTerm'
TERM_PROGRAM="Apple_Terminal"
LC_TERMINAL=""
When call iterm_mark
The status should be success
End
End

Describe 'iterm_notify function'
It 'is defined'
When call type iterm_notify
The status should be success
The output should not be blank
End

It 'succeeds when not in iTerm'
TERM_PROGRAM="Apple_Terminal"
LC_TERMINAL=""
When call iterm_notify "test message"
The status should be success
End
End

Describe 'iterm_set_title function'
It 'is defined'
When call type iterm_set_title
The status should be success
The output should not be blank
End

It 'succeeds with a title argument'
When call iterm_set_title "My Title"
The status should be success
End

It 'succeeds with empty title'
When call iterm_set_title ""
The status should be success
End
End

Describe 'validate_image_file function'
setup() {
  TEST_DIR=$(mktemp -d)
  VALID_IMAGE="$TEST_DIR/test.png"
  EMPTY_FILE="$TEST_DIR/empty.png"
  TEXT_FILE="$TEST_DIR/text.txt"

  printf '\x89PNG\r\n\x1a\n' >"$VALID_IMAGE"
  printf '\x00\x00\x00\x0d\x49\x48\x44\x52' >>"$VALID_IMAGE"
  touch "$EMPTY_FILE"
  echo "not an image" >"$TEXT_FILE"
}

cleanup() {
  [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

Before 'setup'
After 'cleanup'

It 'returns failure for missing file'
When call validate_image_file "$TEST_DIR/nonexistent.png"
The status should be failure
End

It 'returns failure for empty file'
When call validate_image_file "$EMPTY_FILE"
The status should be failure
End

It 'returns failure for non-image file'
When call validate_image_file "$TEXT_FILE"
The status should be failure
End

It 'returns success for valid PNG file'
When call validate_image_file "$VALID_IMAGE"
The status should be success
End
End

Describe 'download_image function'
setup() {
  TEST_DIR=$(mktemp -d)
  OUTPUT_FILE="$TEST_DIR/output.png"
}

cleanup() {
  [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

Before 'setup'
After 'cleanup'

It 'returns failure when curl produces a non-image file'
curl() {
  echo "not an image" >"$OUTPUT_FILE"
  return 0
}
When call download_image "http://example.com/fake.png" "$OUTPUT_FILE" 1
The status should be failure
End

It 'returns success when curl produces a valid image'
curl() {
  printf '\x89PNG\r\n\x1a\n\x00\x00\x00\x0d\x49\x48\x44\x52' >"$OUTPUT_FILE"
  return 0
}
When call download_image "http://example.com/image.png" "$OUTPUT_FILE" 1
The status should be success
End

It 'returns failure when curl exits with error'
curl() {
  return 1
}
When call download_image "http://example.com/image.png" "$OUTPUT_FILE" 1
The status should be failure
End
End

Describe 'tty_is_available function'
It 'is defined'
When call type tty_is_available
The status should be success
The output should not be blank
End

It 'returns a consistent boolean result'
When call tty_is_available
The status should be defined
End
End

Describe 'iterm_can_display_images function'
It 'returns success when TERM_PROGRAM is iTerm.app'
TERM_PROGRAM="iTerm.app"
LC_TERMINAL=""
When call iterm_can_display_images
The status should be success
End

It 'returns failure when not in iTerm'
TERM_PROGRAM="Apple_Terminal"
LC_TERMINAL=""
When call iterm_can_display_images
The status should be failure
End
End

Describe '_fetch_count_with_timeout function'
setup() {
  TEST_DIR=$(mktemp -d)
  LOG_FILE="$TEST_DIR/test.log"
  CALL_COUNT_FILE="$TEST_DIR/call_count"
  echo "0" >"$CALL_COUNT_FILE"
}

cleanup() {
  [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

Before 'setup'
After 'cleanup'

It 'is defined'
When call type _fetch_count_with_timeout
The status should be success
The output should not be blank
End

It 'calls osascript exactly once (not twice)'
# This test exposes a bug: the current implementation runs osascript twice
# First to check success (discarding output), then again to capture the value
# This is inefficient and can cause race conditions

# Mock osascript to count calls and return a value
osascript() {
  local count=$(cat "$CALL_COUNT_FILE")
  echo $((count + 1)) >"$CALL_COUNT_FILE"
  echo "6"
  return 0
}

# Mock timeout to just run the command directly
timeout() {
  shift
  "$@"
}

_fetch_count_with_timeout "/fake/script.scpt" >/dev/null

call_count=$(cat "$CALL_COUNT_FILE")
The variable call_count should equal "1"
End
End
End
