#!/usr/bin/env zsh

# Error Handling Design: This script intentionally does not use 'set -euo pipefail'
# to allow graceful degradation when optional features are unavailable. Each function
# handles its own errors and the script continues running even if individual features
# fail (e.g., weather API unavailable, calendar app not running). This design prioritizes
# user experience over strict error propagation.

###############################################################################
# Configuration and Constants
###############################################################################

# Determine script directory (works for both execution and sourcing)
# Priority 1: Environment variable override (primarily for testing)
if [[ -n "$GOODMORNING_SCRIPT_DIR" ]]; then
  SCRIPT_DIR="$GOODMORNING_SCRIPT_DIR"

# Priority 2: Zsh-specific method (most reliable when sourced in zsh)
# ${(%):-%x} expands to the path of the sourced/executed script file
else
  local ZSH_SCRIPT_PATH="${(%):-%x}"

  # Validate zsh script path (filter out edge cases)
  if [[ -n "$ZSH_SCRIPT_PATH" && "$ZSH_SCRIPT_PATH" != "/dev/fd/"* && "$ZSH_SCRIPT_PATH" != "zsh" && "$ZSH_SCRIPT_PATH" != "bash" ]]; then
    # Resolve symlinks to get the real script location
    if [[ -L "$ZSH_SCRIPT_PATH" ]]; then
      local REAL_PATH="$(readlink "$ZSH_SCRIPT_PATH")"
      SCRIPT_DIR="$(cd "$(dirname "$REAL_PATH")" && pwd)"
    else
      SCRIPT_DIR="$(cd "$(dirname "$ZSH_SCRIPT_PATH")" && pwd)"
    fi

  # Priority 3: Bash-specific method (fallback for bash compatibility)
  # BASH_SOURCE[0] contains the path to the sourced/executed script in bash
  elif [[ -n "${BASH_SOURCE[0]}" ]]; then
    # Resolve symlinks to get the real script location
    if [[ -L "${BASH_SOURCE[0]}" ]]; then
      local REAL_PATH="$(readlink "${BASH_SOURCE[0]}")"
      SCRIPT_DIR="$(cd "$(dirname "$REAL_PATH")" && pwd)"
    else
      SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi

  # Priority 4: Search common installation locations
  else
    # Check current directory
    if [[ -f "$PWD/goodmorning.sh" ]]; then
      SCRIPT_DIR="$PWD"
    # Check standard config location
    elif [[ -f "$HOME/.config/goodmorning/goodmorning.sh" ]]; then
      SCRIPT_DIR="$HOME/.config/goodmorning"
    # Last resort: use current directory with warning
    else
      echo "Warning: Could not determine script directory. Set GOODMORNING_SCRIPT_DIR environment variable." >&2
      SCRIPT_DIR="$(pwd)"
    fi
  fi
fi

if [ -f "$SCRIPT_DIR/lib/colors.sh" ]; then
  source "$SCRIPT_DIR/lib/colors.sh"
fi

if [ -f "$SCRIPT_DIR/lib/core.sh" ]; then
  source "$SCRIPT_DIR/lib/core.sh"
fi

if [ -f "$SCRIPT_DIR/lib/updates.sh" ]; then
  source "$SCRIPT_DIR/lib/updates.sh"
fi

if [ -f "$SCRIPT_DIR/lib/display.sh" ]; then
  source "$SCRIPT_DIR/lib/display.sh"
fi

if [ -f "$SCRIPT_DIR/lib/learning.sh" ]; then
  source "$SCRIPT_DIR/lib/learning.sh"
fi

if [ -f "$SCRIPT_DIR/lib/versions.sh" ]; then
  source "$SCRIPT_DIR/lib/versions.sh"
fi

if [ -f "$SCRIPT_DIR/lib/daily_content.sh" ]; then
  source "$SCRIPT_DIR/lib/daily_content.sh"
fi

# ZSH default pattern, assigns the left side of := only if not already set
: ${MAX_REMINDERS:="${GOODMORNING_MAX_REMINDERS:-10}"}
: ${MAX_EMAILS:="${GOODMORNING_MAX_EMAILS:-5}"}
: ${MAX_HISTORY_EVENTS:="${GOODMORNING_MAX_HISTORY_EVENTS:-3}"}
: ${MAX_REPOS_TO_SCAN:="${GOODMORNING_MAX_REPOS:-10}"}
: ${MAX_COMMITS_PER_REPO:="${GOODMORNING_MAX_COMMITS:-5}"}
: ${GIT_SCAN_DEPTH:="${GOODMORNING_GIT_DEPTH:-3}"}
: ${GIT_LOOKBACK_DAYS:="${GOODMORNING_GIT_DAYS:-7}"}
: ${MAX_CONTEXT_LENGTH:="${GOODMORNING_MAX_CONTEXT:-2000}"}
: ${GIT_SCAN_TIMEOUT:="${GOODMORNING_GIT_TIMEOUT:-5}"}
: ${SPINNER_TIMEOUT:="${GOODMORNING_SPINNER_TIMEOUT:-30}"}
: ${UPDATES_LOG_PATTERN:="/tmp/goodmorning_updates.XXXXXX"}
: ${CLAUDE_TIP_PATTERN:="/tmp/claude_tip.XXXXXX"}

# User configuration (override via GOODMORNING_* environment variables)
# Default to script directory for immediate use, override with setup or environment
CONFIG_DIR="${GOODMORNING_CONFIG_DIR:-$SCRIPT_DIR}"
# Export for lib files that use GOODMORNING_CONFIG_DIR directly
export GOODMORNING_CONFIG_DIR="$CONFIG_DIR"
USER_NAME="${GOODMORNING_USER_NAME:-${USER}}"

# Optional scripts (defaults point to example templates - copy and customize these)
BACKUP_SCRIPT="${GOODMORNING_BACKUP_SCRIPT:-$SCRIPT_DIR/examples/backup-script-template.sh}"
PROJECT_DIRS="${GOODMORNING_PROJECT_DIRS:-$HOME}"
COMPLETION_CALLBACK="${GOODMORNING_COMPLETION_CALLBACK:-$SCRIPT_DIR/examples/completion-callback-template.sh}"

# Feature flags
SHOW_SETUP_MESSAGES="${GOODMORNING_SHOW_SETUP_MESSAGES:-true}"

# Files default to CONFIG_DIR (which defaults to SCRIPT_DIR for immediate use)
BANNER_FILE="${GOODMORNING_BANNER_FILE:-$CONFIG_DIR/banner.txt}"
LEARNING_SOURCES_FILE="${GOODMORNING_LEARNING_SOURCES_FILE:-$CONFIG_DIR/learning-sources.txt}"

# Logging
LOGS_DIR="${GOODMORNING_LOGS_DIR:-$CONFIG_DIR/logs}"
LOG_FILE="$LOGS_DIR/goodmorning.log"

TEMP_FILES=()
BACKGROUND_PIDS=()

main() {
  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --noisy)
        export GOODMORNING_ENABLE_TTS=true
        shift
        ;;
      --help|-h)
        echo "Usage: goodmorning.sh [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --noisy    Enable text-to-speech greeting"
        echo "  --help     Show this help message"
        return 0
        ;;
      *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        return 1
        ;;
    esac
  done

  # Initialize logging
  mkdir -p "$LOGS_DIR" 2>/dev/null
  echo "========================================" >> "$LOG_FILE"
  echo "Good Morning - $(date)" >> "$LOG_FILE"
  echo "========================================" >> "$LOG_FILE"

  _check_dependencies || exit 1

  start_background_updates
  show_banner
  show_weather
  show_history
  show_tech_versions
  show_country_of_day
  show_word_of_day
  show_wikipedia_featured
  show_apod
  show_calendar
  show_reminders
  show_email
  show_daily_learning
  show_learning_tips

  if [ -n "$COMPLETION_CALLBACK" ]; then
    print_section "Completion Callback"
    _safe_source "$COMPLETION_CALLBACK" || echo_warning "Completion callback failed"
    echo ""
  fi

  echo_gray "Log: ${LOG_FILE}"
}

# Run when the file is sourced, unless we want to load the file and test things.
if [[ -z "$GOODMORNING_NO_AUTO_RUN" ]]; then
  main "$@"
fi