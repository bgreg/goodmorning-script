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
      echo '#!/usr/bin/env zsh' > "$VALID_FILE"
      echo 'TEST_VAR="loaded"' >> "$VALID_FILE"
      chmod 644 "$VALID_FILE"

      # World-writable file (security risk)
      echo '#!/usr/bin/env zsh' > "$WORLD_WRITABLE"
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

  Describe '_fetch_count_with_timeout function'
    setup() {
      TEST_DIR=$(mktemp -d)
      LOG_FILE="$TEST_DIR/test.log"
      CALL_COUNT_FILE="$TEST_DIR/call_count"
      echo "0" > "$CALL_COUNT_FILE"
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
        echo $((count + 1)) > "$CALL_COUNT_FILE"
        echo "6"
        return 0
      }

      # Mock timeout to just run the command directly
      timeout() { shift; "$@"; }

      _fetch_count_with_timeout "/fake/script.scpt" >/dev/null

      call_count=$(cat "$CALL_COUNT_FILE")
      The variable call_count should equal "1"
    End
  End
End
