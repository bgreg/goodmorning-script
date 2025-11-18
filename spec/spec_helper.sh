#!/usr/bin/env zsh
#
# ShellSpec Helper
# Provides test utilities and mocking for ShellSpec tests

# shellcheck shell=bash

set +e  # ShellSpec handles errors

# Project paths - use SHELLSPEC_PROJECT_ROOT which ShellSpec provides
export PROJECT_ROOT="${SHELLSPEC_PROJECT_ROOT:-$(pwd)}"
export SCRIPT_DIR="$PROJECT_ROOT"

# Prevent auto-execution of scripts during tests
export GOODMORNING_NO_AUTO_RUN=1
export GOODMORNING_SHOW_SETUP_MESSAGES=false

# Mock commands to prevent side effects
mock_open_command() {
  export OPEN_CALLS_LOG="${OPEN_CALLS_LOG:-$(mktemp)}"

  open() {
    echo "[MOCK] Would open: $*" >&2
    echo "$*" >> "$OPEN_CALLS_LOG"
    return 0
  }

  export -f open
}

mock_say_command() {
  export SAY_CALLS_LOG="${SAY_CALLS_LOG:-$(mktemp)}"

  say() {
    echo "[MOCK] Would say: $*" >&2
    echo "$*" >> "$SAY_CALLS_LOG"
    return 0
  }

  export -f say
}

mock_osascript_command() {
  osascript() {
    case "$*" in
      *"Mail"*"is running"*)
        echo "false"
        ;;
      *"count"*"message"*)
        echo "0"
        ;;
      *"count"*"reminder"*)
        echo "0"
        ;;
      *)
        return 0
        ;;
    esac
  }

  export -f osascript
}

# Auto-mock common commands
mock_open_command
mock_say_command
mock_osascript_command

# Cleanup function
cleanup_mocks() {
  [ -n "$OPEN_CALLS_LOG" ] && [ -f "$OPEN_CALLS_LOG" ] && rm -f "$OPEN_CALLS_LOG"
  [ -n "$SAY_CALLS_LOG" ] && [ -f "$SAY_CALLS_LOG" ] && rm -f "$SAY_CALLS_LOG"

  unset OPEN_CALLS_LOG
  unset SAY_CALLS_LOG

  unset -f open 2>/dev/null || true
  unset -f say 2>/dev/null || true
  unset -f osascript 2>/dev/null || true
}

# ShellSpec AfterAll hook
spec_helper_cleanup() {
  cleanup_mocks
}

# Verification helpers
url_was_opened() {
  [ -f "$OPEN_CALLS_LOG" ] && grep -q "$1" "$OPEN_CALLS_LOG"
}

say_was_called() {
  [ -f "$SAY_CALLS_LOG" ] && grep -q "$1" "$SAY_CALLS_LOG"
}

# Source script safely
source_goodmorning() {
  export GOODMORNING_SCRIPT_DIR="$PROJECT_ROOT"
  export GOODMORNING_NO_AUTO_RUN=1
  # Source in current shell context
  . "$PROJECT_ROOT/goodmorning.sh"
}

source_setup() {
  # Source in current shell context
  . "$PROJECT_ROOT/setup.sh"
}
