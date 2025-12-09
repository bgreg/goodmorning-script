#!/usr/bin/env zsh

###############################################################################
# Initialization and Orchestration
#
# Handles script startup, output management, and display framing:
#   - Output history setup and cleanup
#   - Preflight validation
#   - Header and footer display
###############################################################################

###############################################################################
# Output History Management
###############################################################################

setup_output_history() {
  local day_name=$(date +%A)
  local day_dir="$OUTPUT_HISTORY_DIR/$day_name"

  mkdir -p "$day_dir"

  # Find next file number for today
  local count=1
  while [[ -f "$day_dir/goodmorning-${count}.txt" ]]; do
    count=$((count + 1))
  done

  OUTPUT_HISTORY_FILE="$day_dir/goodmorning-${count}.txt"

  # Clean up old days (keep only 7 days)
  for old_dir in "$OUTPUT_HISTORY_DIR"/*/; do
    if [[ -d "$old_dir" ]]; then
      local dir_age=$(find "$old_dir" -maxdepth 0 -mtime +6 2>/dev/null)
      if [[ -n "$dir_age" ]]; then
        rm -rf "$old_dir"
      fi
    fi
  done
}

###############################################################################
# Logging Initialization
###############################################################################

init_logging() {
  mkdir -p "$LOGS_DIR" 2>/dev/null

  echo "========================================" >> "$LOG_FILE"
  echo "Good Morning - $(date)" >> "$LOG_FILE"
  echo "========================================" >> "$LOG_FILE"
}

###############################################################################
# Preflight Validation
###############################################################################

run_preflight_checks() {
  if ! check_os; then
    echo_error "This script requires macOS"
    return 1
  fi

  if ! check_shell; then
    echo_error "This script requires zsh"
    return 1
  fi

  if ! check_directories; then
    echo_error "Required directories not accessible"
    return 1
  fi

  if ! check_required_tools >/dev/null 2>&1; then
    echo_error "Missing required tools. Run with --doctor for details."
    return 1
  fi

  return 0
}

###############################################################################
# Display Header/Footer
###############################################################################

show_header() {
  show_banner
  show_new_line

  local badge_status=$(iterm_create_status_badge 2>/dev/null)
  iterm_set_badge "$badge_status"

  check_internet >/dev/null 2>&1 && echo_green "✓" || echo_yellow "⚠"
  show_new_line
}

show_footer() {
  echo_gray "Log: ${LOG_FILE}"
  echo_gray "Output saved: ${OUTPUT_HISTORY_FILE}"
  show_new_line
  echo_gray "💡 iTerm2 Navigation: Use \"command + shift + up\" or \"command + shift + down\" to jump between section checkpoints"
  iterm_notify "Good Morning briefing complete"
  iterm_set_badge ""
}
