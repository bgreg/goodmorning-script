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
  if [ "$UPDATE_HOMEBREW" != "true" ]; then
    show_setup_message "\n⊘ Skipping Homebrew updates (disabled in config)"
    return 0
  fi

  print "\n📦 Updating Homebrew..."
  brew update 2>&1

  print "\n⬆️  Upgrading Homebrew formulae (nvim, etc.)..."
  brew upgrade 2>&1

  local cask_count=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')
  if [ "$cask_count" -gt 0 ]; then
    print "\n🌐 Upgrading $cask_count Homebrew casks..."
    brew upgrade --cask 2>&1 || true
  else
    print "\n⊘ No Homebrew casks installed"
  fi

  print "\n🧹 Cleaning up Homebrew cache..."
  brew cleanup --prune=7 2>&1
  echo_success "Brew cleanup complete"

  print "\n🩺 Running brew doctor..."
  if brew doctor 2>&1; then
    echo_success "Brew doctor: All good!"
  else
    echo_warning "Brew doctor found issues"
  fi
}

_update_claude_code() {
  if [ "$UPDATE_CLAUDE" != "true" ]; then
    show_setup_message "\n⊘ Skipping Claude Code updates (disabled in config)"
    return 0
  fi

  print "\n🤖 Updating Claude Code..."
  if command_exists claude; then
    npm update -g @anthropic-ai/claude-code 2>&1 || echo_success "Claude Code is already up to date"
  else
    echo_warning "Claude Code not found"
  fi
}

_update_vim_plugins() {
  local vim_plugins_dir="${GOODMORNING_VIM_PLUGINS_DIR:-$HOME/.vim/pack/vendor/start}"

  if [ ! -d "$vim_plugins_dir" ]; then
    show_setup_message "\n⊘ Skipping Vim plugin updates (directory not found: $vim_plugins_dir)"
    return 0
  fi

  print "\n📝 Updating Vim plugins in $vim_plugins_dir..."
  local updated=0
  local failed=0

  for plugin_dir in "$vim_plugins_dir"/*/; do
    if [ -d "$plugin_dir/.git" ]; then
      local plugin_name=$(basename "$plugin_dir")
      print "  Updating $plugin_name..."
      if (cd "$plugin_dir" && git pull --quiet 2>&1); then
        ((updated++))
      else
        echo_warning "  Failed to update $plugin_name"
        ((failed++))
      fi
    fi
  done

  if [ $updated -gt 0 ] || [ $failed -gt 0 ]; then
    echo_success "Vim plugins: $updated updated, $failed failed"
  else
    print "  No git-managed plugins found"
  fi
}

_update_nvim_plugins() {
  local nvim_plugins_dir="$HOME/.local/share/nvim/lazy"

  if [ ! -d "$nvim_plugins_dir" ]; then
    nvim_plugins_dir="$HOME/.local/share/nvim/site/pack/*/start"
    if ! ls -d $nvim_plugins_dir 2>/dev/null | head -1 >/dev/null; then
      show_setup_message "\n⊘ Skipping Neovim plugin updates (no plugin directory found)"
      return 0
    fi
  fi

  print "\n Updating Neovim plugins..."

  # For lazy.nvim managed plugins
  if [ -d "$HOME/.local/share/nvim/lazy" ]; then
    local updated=0
    local failed=0

    for plugin_dir in "$HOME/.local/share/nvim/lazy"/*/; do
      if [ -d "$plugin_dir/.git" ]; then
        local plugin_name=$(basename "$plugin_dir")
        print "  Updating $plugin_name..."
        if (cd "$plugin_dir" && git pull --quiet 2>&1); then
          ((updated++))
        else
          echo_warning "  Failed to update $plugin_name"
          ((failed++))
        fi
      fi
    done

    if [ $updated -gt 0 ] || [ $failed -gt 0 ]; then
      echo_success "Neovim plugins: $updated updated, $failed failed"
    fi
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
    _update_vim_plugins
    _update_nvim_plugins

    print "\nCompleted at $(date)"
  } > "$log_file" 2>&1

  echo -e "\n${COLOR_GREEN}========================================${COLOR_RESET}" >> "$log_file"
  echo -e "${COLOR_GREEN}✓ Background updates complete!${COLOR_RESET}" >> "$log_file"
  echo -e "${COLOR_GREEN}========================================${COLOR_RESET}" >> "$log_file"
  echo -e "${COLOR_CYAN}Log file: ${log_file}${COLOR_RESET}\n" >> "$log_file"

  osascript "$SCRIPT_DIR/lib/app/apple_scripts/show_notification.scpt" \
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
