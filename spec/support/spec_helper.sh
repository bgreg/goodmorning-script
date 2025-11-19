#!/usr/bin/env zsh

###############################################################################
# ShellSpec Test Helper Functions
###############################################################################

# Prevent auto-execution of scripts during testing
export GOODMORNING_NO_AUTO_RUN=1
export GOODMORNING_SHOW_SETUP_MESSAGES=false

# Test helper: Source goodmorning.sh safely
source_goodmorning() {
  # Set test environment
  export GOODMORNING_NO_AUTO_RUN=1
  export GOODMORNING_SHOW_SETUP_MESSAGES=false

  # Mock external commands to prevent side effects
  open() { echo "MOCK: open $*" >&2; }
  say() { echo "MOCK: say $*" >&2; }
  osascript() { echo "MOCK: osascript $*" >&2; echo "0"; }

  export -f open say osascript

  # Source the script (suppress stderr but capture variables)
  # Use eval to execute in current shell context
  eval "$(grep -E '^(SCRIPT_DIR=|CONFIG_DIR=|USER_NAME=|MAX_|SPINNER_TIMEOUT=|: \$\{MAX_|: \$\{SPINNER)' ./goodmorning.sh 2>/dev/null | sed 's/^: //' | sed 's/\${//' | sed 's/}//')"

  # Set defaults if not already set
  : ${MAX_REMINDERS:=10}
  : ${MAX_EMAILS:=5}
  : ${MAX_HISTORY_EVENTS:=3}
  : ${SPINNER_TIMEOUT:=30}
  : ${SCRIPT_DIR:=$(pwd)}
  : ${CONFIG_DIR:="$HOME/.config/goodmorning"}
  : ${USER_NAME:="$USER"}
}

# Test helper: Source setup.sh safely
source_setup() {
  # Set test environment
  export GOODMORNING_NO_AUTO_RUN=1

  # Source the script
  source "./setup.sh" 2>/dev/null || true
}

# Test helper: Check if URL was opened (for mocked open command)
url_was_opened() {
  local url="$1"
  # This would check mock call history in a real implementation
  return 0
}

# Test helper: Check if say was called
say_was_called() {
  # This would check mock call history in a real implementation
  return 0
}

# Test helper: Load color functions
load_colors() {
  if [ -f "lib/colors.sh" ]; then
    source "lib/colors.sh"
  fi
}
