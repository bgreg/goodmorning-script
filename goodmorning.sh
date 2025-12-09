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
  ZSH_SCRIPT_PATH="${(%):-%x}"

  # Validate zsh script path (filter out edge cases)
  if [[ -n "$ZSH_SCRIPT_PATH" && "$ZSH_SCRIPT_PATH" != "/dev/fd/"* && "$ZSH_SCRIPT_PATH" != "zsh" && "$ZSH_SCRIPT_PATH" != "bash" ]]; then
    # Resolve symlinks to get the real script location
    if [[ -L "$ZSH_SCRIPT_PATH" ]]; then
      REAL_PATH="$(readlink "$ZSH_SCRIPT_PATH")"
      SCRIPT_DIR="$(cd "$(dirname "$REAL_PATH")" && pwd)"
    else
      SCRIPT_DIR="$(cd "$(dirname "$ZSH_SCRIPT_PATH")" && pwd)"
    fi

  # Priority 3: Bash-specific method (fallback for bash compatibility)
  # BASH_SOURCE[0] contains the path to the sourced/executed script in bash
  elif [[ -n "${BASH_SOURCE[0]}" ]]; then
    # Resolve symlinks to get the real script location
    if [[ -L "${BASH_SOURCE[0]}" ]]; then
      REAL_PATH="$(readlink "${BASH_SOURCE[0]}")"
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

###############################################################################
# Library Sourcing Helper
###############################################################################

# Helper function to source library files with optional required validation
# Usage: _source_lib "lib/app/colors.sh" [required]
# Returns: 0 if file sourced successfully, 1 if file missing
_source_lib() {
  local file="$SCRIPT_DIR/$1"
  local required="${2:-}"

  if [ -f "$file" ]; then
    source "$file"
    return 0
  else
    if [[ "$required" == "required" ]]; then
      echo "Error: Required file missing: $1" >&2
      return 1
    fi
    return 1
  fi
}

###############################################################################
# Source Library Files
###############################################################################

# Core dependencies (must load first, order matters)
_source_lib "lib/utilities.sh" required
_source_lib "lib/app/colors.sh" required
_source_lib "lib/app/core.sh" required

# Preflight checks
for module in environment network tools; do
  _source_lib "lib/app/preflight/${module}.sh"
done

# Core application modules
for module in updates display learning versions view_helpers; do
  _source_lib "lib/app/${module}.sh"
done

# Daily content sections (order doesn't matter)
for section in country_of_day word_of_day wikipedia_featured astronomy_picture cat_of_day alias_suggestions common_typos system_info; do
  _source_lib "lib/app/sections/${section}.sh"
done

# Additional modules
for module in sanity_maintenance github; do
  _source_lib "lib/app/${module}.sh"
done

# ZSH default pattern, assigns the left side of := only if not already set
: ${MAX_REMINDERS:="${GOODMORNING_MAX_REMINDERS:-10}"}
: ${MAX_GITHUB_NOTIFICATIONS:="${GOODMORNING_MAX_GITHUB_NOTIFICATIONS:-5}"}
: ${MAX_GITHUB_PRS:="${GOODMORNING_MAX_GITHUB_PRS:-5}"}
: ${MAX_GITHUB_ISSUES:="${GOODMORNING_MAX_GITHUB_ISSUES:-5}"}
: ${MAX_HISTORY_EVENTS:="${GOODMORNING_MAX_HISTORY_EVENTS:-3}"}
: ${MAX_REPOS_TO_SCAN:="${GOODMORNING_MAX_REPOS:-30}"}
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

# Feature flags - general
SHOW_SETUP_MESSAGES="${GOODMORNING_SHOW_SETUP_MESSAGES:-true}"
OPEN_LINKS="${GOODMORNING_OPEN_LINKS:-true}"

# Feature flags - briefing sections (all enabled by default)
SHOW_WEATHER="${GOODMORNING_SHOW_WEATHER:-true}"
SHOW_HISTORY="${GOODMORNING_SHOW_HISTORY:-true}"
SHOW_TECH_VERSIONS="${GOODMORNING_SHOW_TECH_VERSIONS:-true}"
SHOW_COUNTRY="${GOODMORNING_SHOW_COUNTRY:-true}"
SHOW_WORD="${GOODMORNING_SHOW_WORD:-true}"
SHOW_WIKIPEDIA="${GOODMORNING_SHOW_WIKIPEDIA:-true}"
SHOW_APOD="${GOODMORNING_SHOW_APOD:-true}"
SHOW_CAT="${GOODMORNING_SHOW_CAT:-true}"
SHOW_CALENDAR="${GOODMORNING_SHOW_CALENDAR:-true}"
SHOW_REMINDERS="${GOODMORNING_SHOW_REMINDERS:-true}"
SHOW_GITHUB="${GOODMORNING_SHOW_GITHUB:-true}"
SHOW_GITHUB_PRS="${GOODMORNING_SHOW_GITHUB_PRS:-true}"
SHOW_GITHUB_ISSUES="${GOODMORNING_SHOW_GITHUB_ISSUES:-true}"
SHOW_ALIAS_SUGGESTIONS="${GOODMORNING_SHOW_ALIAS_SUGGESTIONS:-true}"
SHOW_TYPOS="${GOODMORNING_SHOW_TYPOS:-true}"
SHOW_SYSTEM_INFO="${GOODMORNING_SHOW_SYSTEM_INFO:-true}"
SHOW_LEARNING="${GOODMORNING_SHOW_LEARNING:-true}"
SHOW_SANITY="${GOODMORNING_SHOW_SANITY:-true}"
SHOW_TIPS="${GOODMORNING_SHOW_TIPS:-true}"
RUN_UPDATES="${GOODMORNING_RUN_UPDATES:-true}"

# Reminders configuration
REMINDERS_LIST="${GOODMORNING_REMINDERS_LIST:-}"

# Files default to CONFIG_DIR (which defaults to SCRIPT_DIR for immediate use)
BANNER_FILE="${GOODMORNING_BANNER_FILE:-$CONFIG_DIR/banner.txt}"
LEARNING_SOURCES_FILE="${GOODMORNING_LEARNING_SOURCES_FILE:-$CONFIG_DIR/learning-sources.txt}"

# Logging
LOGS_DIR="${GOODMORNING_LOGS_DIR:-$CONFIG_DIR/logs}"
LOG_FILE="$LOGS_DIR/goodmorning.log"

# Output history (must be after CONFIG_DIR is defined)
: ${OUTPUT_HISTORY_DIR:="${GOODMORNING_OUTPUT_HISTORY_DIR:-$CONFIG_DIR/output_history}"}

TEMP_FILES=()
BACKGROUND_PIDS=()

# Setup output history logging
_setup_output_history() {
  local day_name=$(date +%A)
  local day_dir="$OUTPUT_HISTORY_DIR/$day_name"

  # Create day directory
  mkdir -p "$day_dir"

  # Find next file number for today
  local count=1
  while [ -f "$day_dir/goodmorning-${count}.txt" ]; do
    count=$((count + 1))
  done

  OUTPUT_HISTORY_FILE="$day_dir/goodmorning-${count}.txt"

  # Clean up old days (keep only 7 days)
  local current_day_num=$(date +%u)
  for old_dir in "$OUTPUT_HISTORY_DIR"/*/; do
    if [ -d "$old_dir" ]; then
      local dir_name=$(basename "$old_dir")
      # Check if this directory is older than 7 days by checking modification time
      local dir_age=$(find "$old_dir" -maxdepth 0 -mtime +6 2>/dev/null)
      if [ -n "$dir_age" ]; then
        rm -rf "$old_dir"
      fi
    fi
  done
}

main() {
  # Load zsh utilities module for zparseopts
  zmodload zsh/zutil

  # Parse command line arguments using zparseopts
  local -A opts
  zparseopts -D -E -A opts -- \
    h -help \
    -noisy \
    -doctor \
    -offline

  # Handle help
  if [[ -n "${opts[--help]}" || -n "${opts[-h]}" ]]; then
    echo "Usage: goodmorning.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --noisy     Enable text-to-speech greeting"
    echo "  --doctor    Run system diagnostics and validation"
    echo "  --offline   Run in offline mode (skip network features)"
    echo "  -h, --help  Show this help message"
    return 0
  fi

  # Handle doctor mode
  if [[ -n "${opts[--doctor]}" ]]; then
    # Source validation for doctor functions
    if [ -f "$SCRIPT_DIR/lib/validation.sh" ]; then
      source "$SCRIPT_DIR/lib/validation.sh"
      run_doctor
      return $?
    else
      echo "Error: Doctor mode requires validation.sh" >&2
      return 1
    fi
  fi

  # Handle offline mode
  if [[ -n "${opts[--offline]}" ]]; then
    export GOODMORNING_FORCE_OFFLINE=true
  fi

  # Handle TTS mode
  if [[ -n "${opts[--noisy]}" ]]; then
    export GOODMORNING_ENABLE_TTS=true
  fi

  # Initialize logging
  mkdir -p "$LOGS_DIR" 2>/dev/null
  echo "========================================" >> "$LOG_FILE"
  echo "Good Morning - $(date)" >> "$LOG_FILE"
  echo "========================================" >> "$LOG_FILE"

  # Setup signal handlers for graceful exit on Ctrl+C
  _cleanup_and_exit() {
    echo ""
    echo_yellow "Interrupted by user. Cleaning up..."
    iterm_set_badge ""
    exit 130  # Standard exit code for SIGINT (128 + 2)
  }
  trap _cleanup_and_exit INT TERM

  # Setup output history
  _setup_output_history

  # Save original stdout for direct terminal writes (images bypass tee)
  exec 3>&1
  export GOODMORNING_TERMINAL_FD=3

  # Capture all output to history file while still displaying to terminal
  exec > >(tee -a "$OUTPUT_HISTORY_FILE") 2>&1

  # iTerm2: Set window title and badge with status counts
  iterm_set_title "Good Morning - $(date '+%a %b %d')"
  local badge_status=$(iterm_create_status_badge)
  iterm_set_badge "$badge_status"

  # Run preflight checks
  if ! check_os; then
    echo_error "This script requires macOS"
    exit 1
  fi

  if ! check_shell; then
    echo_error "This script requires zsh"
    exit 1
  fi

  if ! check_directories; then
    echo_error "Required directories not accessible"
    exit 1
  fi

  if ! check_required_tools >/dev/null 2>&1; then
    echo_error "Missing required tools. Run with --doctor for details."
    exit 1
  fi

  # Check network (non-fatal)
  check_internet

  [[ "$RUN_UPDATES" == "true" ]] && start_background_updates
  show_banner
  [[ "$SHOW_WEATHER" == "true" ]] && show_weather
  [[ "$SHOW_HISTORY" == "true" ]] && show_history
  [[ "$SHOW_TECH_VERSIONS" == "true" ]] && show_tech_versions
  [[ "$SHOW_COUNTRY" == "true" ]] && show_country_of_day
  [[ "$SHOW_WORD" == "true" ]] && show_word_of_day
  [[ "$SHOW_WIKIPEDIA" == "true" ]] && show_wikipedia_featured
  [[ "$SHOW_APOD" == "true" ]] && show_apod
  [[ "$SHOW_CAT" == "true" ]] && show_cat_of_day
  [[ "$SHOW_CALENDAR" == "true" ]] && show_calendar
  [[ "$SHOW_REMINDERS" == "true" ]] && show_reminders
  [[ "$SHOW_GITHUB" == "true" ]] && show_github_notifications
  [[ "$SHOW_GITHUB_PRS" == "true" ]] && show_github_prs
  [[ "$SHOW_GITHUB_ISSUES" == "true" ]] && show_github_issues
  [[ "$SHOW_ALIAS_SUGGESTIONS" == "true" ]] && show_alias_suggestions
  [[ "$SHOW_TYPOS" == "true" ]] && show_common_typos
  [[ "$SHOW_SYSTEM_INFO" == "true" ]] && show_system_info
  [[ "$SHOW_LEARNING" == "true" ]] && show_daily_learning
  [[ "$SHOW_SANITY" == "true" ]] && show_sanity_maintenance
  [[ "$SHOW_TIPS" == "true" ]] && show_learning_tips

  if [ -n "$COMPLETION_CALLBACK" ]; then
    print_section "Completion Callback"
    safe_source "$COMPLETION_CALLBACK" || echo_warning "Completion callback failed"
    echo ""
  fi

  echo_gray "Log: ${LOG_FILE}"
  echo_gray "Output saved: ${OUTPUT_HISTORY_FILE}"

  # iTerm2: Send completion notification and clear badge
  iterm_notify "Good Morning briefing complete"
  iterm_set_badge ""
}

# Run when the file is sourced, unless we want to load the file and test things.
if [[ -z "$GOODMORNING_NO_AUTO_RUN" ]]; then
  main "$@"
fi