#!/usr/bin/env zsh

###############################################################################
# Update Functions
#
# Handles background system updates and maintenance tasks:
# - Development environment backups
# - Homebrew package updates
# - Claude Code CLI updates
# - Vim plugin updates
# - Orchestration and logging
###############################################################################

_run_backup() {
  if [ -n "$BACKUP_SCRIPT" ]; then
    print "\n💾 Backing up development environment..."
    if [ -f "$BACKUP_SCRIPT" ]; then
      if "$BACKUP_SCRIPT" 2>&1; then
        echo_success "Dev environment backup complete!"
      else
        echo_warning "Backup script failed with exit code $?"
      fi
    else
      echo_warning "Backup script not found at: $BACKUP_SCRIPT"
    fi
  else
    show_setup_message "\n⊘ Skipping backup (GOODMORNING_BACKUP_SCRIPT not configured)"
  fi
}

_update_homebrew() {
  print "\n📦 Updating Homebrew..."
  brew update 2>&1

  print "\n⬆️  Upgrading Homebrew packages..."
  brew upgrade 2>&1

  print "\n🩺 Running brew doctor..."
  if brew doctor 2>&1; then
    echo_success "Brew doctor: All good!"
  else
    echo_warning "Brew doctor found issues"
  fi
}

_update_claude_code() {
  print "\n🤖 Updating Claude Code..."
  if command_exists claude; then
    npm update -g @anthropic-ai/claude-code 2>&1 || echo_success "Claude Code is already up to date"
  else
    echo_warning "Claude Code not found"
  fi
}

_goodmorning_updates() {
  local log_file
  log_file=$(mktemp "$UPDATES_LOG_PATTERN") || {
    echo "Failed to create log file" >&2
    return 1
  }
  TEMP_FILES+=("$log_file")

  {
    echo "Starting updates at $(date)"

    _run_backup
    _update_homebrew
    _update_claude_code

    print "\nCompleted at $(date)"
  } > "$log_file" 2>&1

  # Log file output - manual format for precise control over file content
  echo -e "\n${COLOR_GREEN}========================================${COLOR_RESET}" >> "$log_file"
  echo -e "${COLOR_GREEN}✓ Background updates complete!${COLOR_RESET}" >> "$log_file"
  echo -e "${COLOR_GREEN}========================================${COLOR_RESET}" >> "$log_file"
  echo -e "${COLOR_CYAN}Log file: ${log_file}${COLOR_RESET}\n" >> "$log_file"

  osascript "$SCRIPT_DIR/lib/apple_script/show_notification.scpt" \
    "Backup and system updates complete! Check terminal for details." \
    "Good Morning Complete" >/dev/null 2>&1
}

start_background_updates() {
  print_section "Starting Backup & System Updates..."
  echo_yellow "💾 Backing up dev environment..."
  echo_yellow "📦 Running system updates..."
  echo_yellow "All tasks running in background - you'll get a notification when complete!\n"

  setopt LOCAL_OPTIONS NO_NOTIFY NO_MONITOR
  _goodmorning_updates >/dev/null 2>&1 &
  local update_pid=$!
  BACKGROUND_PIDS+=($update_pid)
  disown %% 2>> "$LOG_FILE"

  echo_green "Updates and backups are running in the background, you will be notified when they complete.\n"

  if [ "${GOODMORNING_ENABLE_TTS:-false}" = "true" ]; then
    say "Good morning ${USER_NAME}" &
  fi
}
