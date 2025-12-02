#!/usr/bin/env zsh

###############################################################################
# Doctor Mode - Comprehensive System Diagnostics
#
# Provides detailed validation of the goodmorning-script environment
# including system requirements, dependencies, configuration, and connectivity.
###############################################################################

# Ensure dependencies are available
SCRIPT_DIR="${SCRIPT_DIR:-${0:a:h:h}}"

if [[ -z "$COLOR_RESET" ]]; then
  source "$SCRIPT_DIR/colors.sh" 2>/dev/null || true
fi

if [ -f "$SCRIPT_DIR/view_helpers.sh" ]; then
  source "$SCRIPT_DIR/view_helpers.sh"
fi

if [ -f "$SCRIPT_DIR/setup/validation_helpers.sh" ]; then
  source "$SCRIPT_DIR/setup/validation_helpers.sh"
fi

run_doctor() {
  local script_dir="${1:-$(cd "$(dirname "${(%):-%x}")" && pwd)}"
  local config_dir="${2:-$HOME/.config/goodmorning}"
  local config_file="$config_dir/config.sh"

  validation_reset_counters

  echo ""
  echo_cyan "════════════════════════════════════════════════════════════════"
  echo_cyan "  Good Morning Script - System Diagnostics"
  echo_cyan "════════════════════════════════════════════════════════════════"

  # Source config if available
  if [[ -f "$config_file" ]]; then
    source "$config_file" 2>/dev/null
    config_dir="${GOODMORNING_CONFIG_DIR:-$config_dir}"
  fi

  doctor_check_system_environment
  doctor_check_terminal_features
  doctor_check_network
  doctor_check_dependencies
  doctor_check_macos_services
  doctor_check_config "$config_dir" "$config_file"
  doctor_check_configured_paths
  doctor_check_api_keys
  doctor_check_permissions "$script_dir"
  doctor_check_symlinks "$script_dir"
  doctor_check_json_files "$script_dir" "$config_dir"
  doctor_check_cache_health "$script_dir"
  doctor_check_urls "$script_dir" "$config_dir"

  doctor_print_summary "$script_dir"
}

doctor_check_system_environment() {
  validation_section "🖥️  System Environment"

  # macOS check
  if [[ "$OSTYPE" == "darwin"* ]]; then
    local macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
    validation_pass "macOS $macos_version"
  else
    validation_fail "Not running on macOS" "This script requires macOS"
  fi

  # Shell version
  if [[ -n "$ZSH_VERSION" ]]; then
    validation_pass "Zsh $ZSH_VERSION"
  else
    validation_warn "Not running in zsh" "Some features may not work correctly"
  fi

  # Locale
  local current_locale="${LC_ALL:-${LANG:-C}}"
  if [[ "$current_locale" == *UTF-8* ]] || [[ "$current_locale" == *utf8* ]]; then
    validation_pass "UTF-8 locale: $current_locale"
  else
    validation_warn "Non-UTF-8 locale: $current_locale" "Some characters may not display correctly"
  fi

  # Timezone
  local tz="${TZ:-$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')}"
  if [[ -n "$tz" ]]; then
    validation_pass "Timezone: $tz"
  else
    validation_info "Timezone: system default"
  fi

  # System time (check if within reasonable range)
  local current_year=$(date +%Y)
  if [[ "$current_year" -ge 2024 ]] && [[ "$current_year" -le 2030 ]]; then
    validation_pass "System date: $(date '+%Y-%m-%d %H:%M')"
  else
    validation_fail "System date appears incorrect" "Year: $current_year"
  fi

  # Disk space for config directory
  local config_parent="${GOODMORNING_CONFIG_DIR:-$HOME/.config}"
  if [[ -d "$config_parent" ]]; then
    local available_kb=$(df -k "$config_parent" 2>/dev/null | awk 'NR==2 {print $4}')
    if [[ -n "$available_kb" ]]; then
      local available_mb=$((available_kb / 1024))
      if [[ "$available_mb" -gt 100 ]]; then
        validation_pass "Disk space: ${available_mb}MB available"
      elif [[ "$available_mb" -gt 10 ]]; then
        validation_warn "Low disk space: ${available_mb}MB" "Consider freeing space"
      else
        validation_fail "Very low disk space: ${available_mb}MB" "May affect cache and logs"
      fi
    fi
  fi

  # Terminal capability
  if [[ -t 1 ]]; then
    local term_type="${TERM:-unknown}"
    if [[ "$term_type" == *color* ]] || [[ "$term_type" == "xterm"* ]] || [[ "$term_type" == "screen"* ]]; then
      validation_pass "Terminal: $term_type (color support)"
    else
      validation_info "Terminal: $term_type"
    fi
  else
    validation_info "Running non-interactively"
  fi
}

doctor_check_terminal_features() {
  validation_section "🖥️  Terminal Features"

  local terminal_emulator="${TERM_PROGRAM:-unknown}"
  local terminal_version="${TERM_PROGRAM_VERSION:-}"

  if [[ "$terminal_emulator" == "iTerm.app" ]] || [[ "$LC_TERMINAL" == "iTerm2" ]]; then
    if [[ -n "$terminal_version" ]]; then
      validation_pass "iTerm2 $terminal_version"
    else
      validation_pass "iTerm2 detected"
    fi

    local iterm_major_version="${terminal_version%%.*}"
    local min_version_for_images=3

    if [[ -n "$iterm_major_version" ]] && [[ "$iterm_major_version" -ge $min_version_for_images ]]; then
      validation_pass "Inline images supported (iTerm2 3.0+)"
    elif [[ -n "$terminal_version" ]]; then
      validation_warn "iTerm2 version may not support images" "Upgrade to 3.0+ for image support"
    else
      validation_pass "Inline images likely supported"
    fi
  elif [[ "$terminal_emulator" == "Apple_Terminal" ]]; then
    validation_pass "Terminal.app detected"
    validation_info "Inline images not supported (iTerm2 feature)"
  elif [[ "$terminal_emulator" == "vscode" ]]; then
    validation_pass "VS Code terminal detected"
    validation_info "Inline images not supported"
  else
    validation_info "Terminal: $terminal_emulator"
    validation_info "Inline images require iTerm2"
  fi

  if command -v imgcat &>/dev/null; then
    validation_pass "imgcat available (iTerm2 shell integration)"
  fi
}

doctor_check_network() {
  validation_section "🌐 Network Connectivity"

  # Basic internet connectivity
  if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
    validation_pass "Internet connectivity (ping)"
  else
    validation_fail "No internet connectivity" "Check your network connection"
  fi

  # DNS resolution
  if host -W 3 google.com &>/dev/null 2>&1 || nslookup -timeout=3 google.com &>/dev/null 2>&1; then
    validation_pass "DNS resolution working"
  else
    validation_warn "DNS resolution may be slow" "Check DNS settings"
  fi

  # HTTPS/SSL connectivity
  if curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" https://api.github.com &>/dev/null; then
    validation_pass "HTTPS/SSL working"
  else
    validation_fail "HTTPS connections failing" "Check SSL certificates or firewall"
  fi

  # Check common API endpoints
  local endpoints=(
    "api.openweathermap.org"
    "api.github.com"
    "en.wikipedia.org"
  )

  local reachable=0
  local total=${#endpoints[@]}

  for endpoint in "${endpoints[@]}"; do
    if curl -s --connect-timeout 3 --max-time 5 -o /dev/null "https://$endpoint" 2>/dev/null; then
      (( reachable++ )) || true
    fi
  done

  if [[ "$reachable" -eq "$total" ]]; then
    validation_pass "API endpoints reachable ($reachable/$total)"
  elif [[ "$reachable" -gt 0 ]]; then
    validation_warn "Some API endpoints unreachable ($reachable/$total)"
  else
    validation_fail "No API endpoints reachable" "Check firewall or proxy settings"
  fi
}

doctor_check_macos_services() {
  validation_section "🍎 macOS Services"

  # Check if osascript works (needed for Mail, Calendar fallbacks)
  if osascript -e 'return "test"' &>/dev/null; then
    validation_pass "osascript (AppleScript) working"
  else
    validation_fail "osascript not working" "AppleScript features will be unavailable"
  fi

  # Calendar access
  if [[ "${GOODMORNING_SHOW_CALENDAR:-true}" == "true" ]]; then
    if osascript -e 'tell application "Calendar" to return name of first calendar' &>/dev/null 2>&1; then
      validation_pass "Calendar.app accessible"
    else
      validation_warn "Calendar.app not accessible" "Grant calendar permissions or use icalBuddy"
    fi
  else
    validation_info "Calendar: disabled in config"
  fi

  # Reminders access
  if [[ "${GOODMORNING_SHOW_REMINDERS:-true}" == "true" ]]; then
    if osascript -e 'tell application "Reminders" to return name of first list' &>/dev/null 2>&1; then
      validation_pass "Reminders.app accessible"
    else
      validation_warn "Reminders.app not accessible" "Grant reminders permissions"
    fi
  else
    validation_info "Reminders: disabled in config"
  fi

  # Notification center
  if osascript -e 'display notification "test" with title "test"' &>/dev/null 2>&1; then
    validation_pass "Notification Center accessible"
  else
    validation_warn "Notification Center not accessible" "Notifications may not appear"
  fi

  # Text-to-speech (if enabled)
  if [[ "${GOODMORNING_ENABLE_TTS:-false}" == "true" ]]; then
    if command -v say &>/dev/null; then
      validation_pass "Text-to-speech (say) available"
    else
      validation_fail "TTS enabled but 'say' command not found"
    fi
  fi
}

doctor_check_configured_paths() {
  validation_section "📂 Configured Paths"

  # Backup script
  local backup_script="${GOODMORNING_BACKUP_SCRIPT:-}"
  if [[ -n "$backup_script" ]]; then
    # Expand variables in path
    backup_script=$(eval echo "$backup_script")
    if [[ -f "$backup_script" ]]; then
      if [[ -x "$backup_script" ]]; then
        validation_pass "Backup script: $backup_script"
      else
        validation_fail "Backup script not executable" "chmod +x $backup_script"
      fi
    else
      validation_fail "Backup script not found" "$backup_script"
    fi
  else
    validation_info "Backup script: not configured"
  fi

  # Project directories
  local project_dirs="${GOODMORNING_PROJECT_DIRS:-}"
  if [[ -n "$project_dirs" ]]; then
    local valid_dirs=0
    local invalid_dirs=0
    local dir_list

    # Split by colon
    IFS=':' read -A dir_list <<< "$project_dirs"

    for dir in "${dir_list[@]}"; do
      dir=$(eval echo "$dir")
      if [[ -d "$dir" ]]; then
        (( valid_dirs++ )) || true
      else
        (( invalid_dirs++ )) || true
      fi
    done

    if [[ "$invalid_dirs" -eq 0 ]]; then
      validation_pass "Project directories: $project_dirs"
    else
      validation_warn "Some project directories missing" "$invalid_dirs of $((valid_dirs + invalid_dirs)) not found"
    fi
  else
    validation_info "Project directories: not configured"
  fi

  # Banner file
  local banner_file="${GOODMORNING_CONFIG_DIR:-$HOME/.config/goodmorning}/banner.txt"
  if [[ -f "$banner_file" ]]; then
    local banner_size=$(wc -c < "$banner_file" | tr -d ' ')
    if [[ "$banner_size" -gt 0 ]]; then
      validation_pass "Banner: $banner_file ($banner_size bytes)"
    else
      validation_warn "Banner file is empty" "$banner_file"
    fi
  else
    validation_info "Custom banner: not configured (using default)"
  fi

  # Logs directory
  local logs_dir="${GOODMORNING_LOGS_DIR:-${GOODMORNING_CONFIG_DIR:-$HOME/.config/goodmorning}/logs}"
  if [[ -d "$logs_dir" ]]; then
    local log_count=$(find "$logs_dir" -name "*.log" -type f 2>/dev/null | wc -l | tr -d ' ')
    validation_pass "Logs: $logs_dir ($log_count files)"
  else
    validation_info "Logs directory will be created on first run"
  fi

  # Output history directory
  local history_dir="${GOODMORNING_OUTPUT_HISTORY_DIR:-${GOODMORNING_CONFIG_DIR:-$HOME/.config/goodmorning}/output_history}"
  if [[ -d "$history_dir" ]]; then
    local history_count=$(find "$history_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
    validation_pass "History: $history_dir ($history_count entries)"
  else
    validation_info "Output history directory will be created on first run"
  fi
}

doctor_check_api_keys() {
  validation_section "🔑 API Keys & Authentication"

  # Weather uses wttr.in (free, no API key required)
  if [[ "${GOODMORNING_SHOW_WEATHER:-true}" == "true" ]]; then
    validation_pass "Weather: uses wttr.in (no API key required)"
  else
    validation_info "Weather: disabled in config"
  fi

  # GitHub CLI authentication
  if [[ "${GOODMORNING_SHOW_GITHUB:-true}" == "true" ]]; then
    if command -v gh &>/dev/null; then
      if timeout 5 gh auth status &>/dev/null 2>&1; then
        local gh_user=$(gh api user --jq .login 2>/dev/null || echo "unknown")
        validation_pass "GitHub authenticated as: $gh_user"
      else
        validation_fail "GitHub CLI not authenticated" "Run: gh auth login"
      fi
    else
      validation_fail "GitHub CLI not installed" "Run: brew install gh"
    fi
  fi

  # Claude Code availability (for learning tips)
  if [[ "${GOODMORNING_SHOW_TIPS:-true}" == "true" ]]; then
    if command -v claude &>/dev/null; then
      validation_pass "Claude Code available for learning tips"
    else
      validation_fail "Learning tips enabled but Claude not found" "npm install -g @anthropic-ai/claude-code"
    fi
  fi
}

doctor_check_symlinks() {
  local script_dir="$1"
  local install_dir="${GOODMORNING_INSTALL_DIR:-$HOME/.config/zsh/scripts}"

  validation_section "🔗 Installation Symlinks"

  if [[ ! -d "$install_dir" ]]; then
    validation_info "Install directory not found: $install_dir"
    return
  fi

  local scripts=("goodmorning.sh" "setup.sh")

  for script in "${scripts[@]}"; do
    local link_path="$install_dir/$script"
    local target_path="$script_dir/$script"

    if [[ -L "$link_path" ]]; then
      local actual_target=$(readlink "$link_path")
      if [[ "$actual_target" == "$target_path" ]]; then
        validation_pass "$script symlink correct"
      else
        validation_warn "$script symlink points elsewhere" "Expected: $target_path, Got: $actual_target"
      fi
    elif [[ -f "$link_path" ]]; then
      validation_warn "$script is a file, not symlink" "May need to re-run setup"
    else
      validation_info "$script not linked in $install_dir"
    fi
  done
}

doctor_check_cache_health() {
  local script_dir="$1"
  local cache_dir="$script_dir/cache"

  if [[ ! -d "$cache_dir" ]]; then
    validation_section "🗄️  Cache Health"
    validation_info "Cache directory not found (will be created on first run)"
    return
  fi

  # Get cache size for title
  local cache_size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
  validation_section "🗄️  Cache Health ($cache_size)"

  # Check for stale cache files (older than 30 days)
  local stale_count=$(find "$cache_dir" -name "*.json" -mtime +30 2>/dev/null | wc -l)
  if [[ "$stale_count" -gt 0 ]]; then
    validation_warn "$stale_count cache files older than 30 days" "Consider clearing with: rm $cache_dir/*.json"
  else
    validation_pass "No stale cache files"
  fi

  # Check for empty cache files
  local empty_count=$(find "$cache_dir" -name "*.json" -empty 2>/dev/null | wc -l)
  if [[ "$empty_count" -gt 0 ]]; then
    validation_warn "$empty_count empty cache files found"
  fi

  # Check for corrupted JSON in cache
  local corrupted=()
  for cache_file in "$cache_dir"/*.json(N); do
    if [[ -f "$cache_file" ]] && [[ -s "$cache_file" ]]; then
      if ! jq empty "$cache_file" 2>/dev/null; then
        corrupted+=("$cache_file")
      fi
    fi
  done

  if [[ ${#corrupted[@]} -gt 0 ]]; then
    validation_warn "${#corrupted[@]} corrupted cache files" "${corrupted[*]}"
  else
    local valid_count=$(find "$cache_dir" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$valid_count" -gt 0 ]]; then
      validation_pass "All $valid_count cache files valid"
    fi
  fi

  # Check cache file ages for freshness
  local cache_files=(
    "wikipedia_featured.json:Wikipedia cache"
    "country_of_day.json:Country cache"
    "word_of_day.json:Word cache"
  )

  for entry in "${cache_files[@]}"; do
    local filename="${entry%%:*}"
    local description="${entry##*:}"
    local filepath="$cache_dir/$filename"

    if [[ -f "$filepath" ]]; then
      local age_hours=$(( ($(date +%s) - $(stat -f %m "$filepath")) / 3600 ))
      if [[ "$age_hours" -gt 168 ]]; then  # Older than 7 days
        validation_info "$description: ${age_hours}h old (may be stale)"
      fi
    fi
  done
}

doctor_check_dependencies() {
  validation_section "📦 Dependencies"

  # Required dependencies
  local required_deps=("curl" "git" "jq")
  for dep in "${required_deps[@]}"; do
    if validate_dependency "$dep"; then
      validation_pass "$dep installed"
    else
      validation_fail "$dep not found" "Required for core functionality"
    fi
  done

  # Optional dependencies (always check, warn if missing)
  local optional_deps=("figlet" "icalBuddy" "brew" "claude" "gh")
  for dep in "${optional_deps[@]}"; do
    if validate_dependency "$dep"; then
      validation_pass "$dep installed"
    else
      validation_warn "$dep not found" "Optional: some features may be limited"
    fi
  done

  # Feature-specific dependency checks (fail if feature enabled but dep missing)
  validation_section "⚙️  Feature Dependencies"

  # Check GitHub notifications
  if [[ "${GOODMORNING_SHOW_GITHUB:-true}" == "true" ]]; then
    if validate_dependency "gh"; then
      if timeout 5 gh auth status &>/dev/null 2>&1; then
        validation_pass "GitHub: gh installed and authenticated"
      else
        validation_fail "GitHub: gh not authenticated" "Run: gh auth login"
      fi
    else
      validation_fail "GitHub notifications enabled but gh not installed" "Run: brew install gh"
    fi
  else
    validation_info "GitHub notifications: disabled"
  fi

  # Check calendar/reminders
  if [[ "${GOODMORNING_SHOW_CALENDAR:-true}" == "true" ]] || [[ "${GOODMORNING_SHOW_REMINDERS:-true}" == "true" ]]; then
    if validate_dependency "icalBuddy"; then
      validation_pass "Calendar/Reminders: icalBuddy installed"
    else
      validation_warn "Calendar/Reminders: icalBuddy not found" "Using fallback (limited functionality)"
    fi
  fi

  # Check learning tips
  if [[ "${GOODMORNING_SHOW_TIPS:-true}" == "true" ]]; then
    if validate_dependency "claude"; then
      validation_pass "Learning tips: Claude Code installed"
    else
      validation_fail "Learning tips enabled but Claude not installed" "Run: npm install -g @anthropic-ai/claude-code"
    fi
  else
    validation_info "Learning tips: disabled"
  fi

  # Check banner generation
  if [[ -n "${GOODMORNING_BANNER_FILE:-}" ]] && [[ ! -f "${GOODMORNING_BANNER_FILE:-}" ]]; then
    if validate_dependency "figlet"; then
      validation_pass "Banner: figlet installed"
    else
      validation_warn "Banner: figlet not found" "Custom banner generation unavailable"
    fi
  fi

  # Check background updates
  if [[ "${GOODMORNING_RUN_UPDATES:-true}" == "true" ]]; then
    if validate_dependency "brew"; then
      validation_pass "Updates: Homebrew installed"
    else
      validation_warn "Updates enabled but Homebrew not found" "Homebrew updates will be skipped"
    fi
  fi
}

doctor_check_config() {
  local config_dir="$1"
  local config_file="$2"

  validation_section "⚙️  Configuration"

  # Config directory
  if validate_directory_exists "$config_dir"; then
    validation_pass "Config directory exists: $config_dir"

    if validate_directory_writable "$config_dir"; then
      validation_pass "Config directory is writable"
    else
      validation_fail "Config directory not writable" "$config_dir"
    fi
  else
    validation_warn "Config directory not found" "Run setup.sh to create: $config_dir"
  fi

  # Config file
  if validate_file_exists "$config_file"; then
    validation_pass "Config file exists: $config_file"

    # Check for required variables
    if [[ -f "$config_file" ]]; then
      source "$config_file" 2>/dev/null

      if [[ -n "${GOODMORNING_USER_NAME:-}" ]]; then
        validation_pass "User name configured: $GOODMORNING_USER_NAME"
      else
        validation_warn "User name not set"
      fi

      # Check logs directory
      local logs_dir="${GOODMORNING_LOGS_DIR:-$config_dir/logs}"
      if validate_directory_exists "$logs_dir"; then
        validation_pass "Logs directory exists"
      else
        validation_info "Logs directory will be created on first run"
      fi

      # Check output history directory
      local history_dir="${GOODMORNING_OUTPUT_HISTORY_DIR:-$config_dir/output_history}"
      if validate_directory_exists "$history_dir"; then
        validation_pass "Output history directory exists"
      else
        validation_info "Output history directory will be created on first run"
      fi
    fi
  else
    validation_warn "Config file not found" "Run setup.sh to create configuration"
  fi
}

doctor_check_permissions() {
  local script_dir="$1"

  validation_section "🔐 Script Permissions"

  # Main scripts
  local main_scripts=("goodmorning.sh" "setup.sh")
  for script in "${main_scripts[@]}"; do
    local script_path="$script_dir/$script"
    if validate_file_exists "$script_path"; then
      if validate_script_permissions "$script_path"; then
        validation_pass "$script is executable"
      else
        validation_fail "$script not executable" "Run: chmod +x $script_path"
      fi
    else
      validation_fail "$script not found" "$script_path"
    fi
  done

  # Library files (sourced, not executed - just check they exist and are readable)
  local lib_dir="$script_dir/lib"
  if validate_directory_exists "$lib_dir"; then
    local lib_files=("$lib_dir"/*.sh(N))
    if [[ ${#lib_files[@]} -gt 0 ]]; then
      local all_readable=true
      local unreadable=()

      for lib_file in "${lib_files[@]}"; do
        if [[ ! -r "$lib_file" ]]; then
          all_readable=false
          unreadable+=("$lib_file")
        fi
      done

      if $all_readable; then
        validation_pass "All library files readable (${#lib_files[@]} files)"
      else
        validation_fail "Some library files not readable" "chmod +r: ${unreadable[*]}"
      fi
    fi
  else
    validation_warn "Library directory not found" "$lib_dir"
  fi

  # Test files
  local tests_dir="$script_dir/tests"
  if validate_directory_exists "$tests_dir"; then
    local test_files=("$tests_dir"/*.sh(N))
    if [[ ${#test_files[@]} -gt 0 ]]; then
      local all_executable=true
      local non_executable=()

      for test_file in "${test_files[@]}"; do
        if ! validate_script_permissions "$test_file"; then
          all_executable=false
          non_executable+=("$test_file")
        fi
      done

      if $all_executable; then
        validation_pass "All test files executable (${#test_files[@]} files)"
      else
        validation_fail "Some test files not executable" "chmod +x: ${non_executable[*]}"
      fi
    fi
  fi
}

doctor_check_json_files() {
  local script_dir="$1"
  local config_dir="$2"

  validation_section "📄 JSON Configuration Files"

  # Project JSON files
  local project_json_files=(
    "$script_dir/learning-sources.json"
    "$script_dir/sanity-maintenance-sources.json"
  )

  for json_file in "${project_json_files[@]}"; do
    if validate_file_exists "$json_file"; then
      if validate_json_file "$json_file"; then
        validation_pass "$json_file is valid JSON"
      else
        validation_fail "$json_file has invalid JSON syntax"
      fi
    else
      validation_info "$json_file not found (optional)"
    fi
  done

  # User config JSON files
  local user_learning="$config_dir/learning-sources.json"
  if validate_file_exists "$user_learning"; then
    if validate_json_file "$user_learning"; then
      validation_pass "$user_learning is valid JSON"
    else
      validation_fail "$user_learning has invalid JSON syntax"
    fi
  fi

  # Cache JSON files
  local cache_dir="$script_dir/cache"
  if validate_directory_exists "$cache_dir"; then
    local cache_files=("$cache_dir"/*.json(N))
    if [[ ${#cache_files[@]} -gt 0 ]]; then
      local valid_count=0
      local invalid_files=()

      for cache_file in "${cache_files[@]}"; do
        if validate_json_file "$cache_file"; then
          (( valid_count++ )) || true
        else
          invalid_files+=("$cache_file")
        fi
      done

      if [[ ${#invalid_files[@]} -eq 0 ]]; then
        validation_pass "Cache: $cache_dir ($valid_count files)"
      else
        validation_warn "Some cache files invalid" "${invalid_files[*]}"
      fi
    fi
  fi
}

doctor_check_urls() {
  local script_dir="$1"
  local config_dir="$2"

  validation_section "🔗 URL Validation"

  echo_cyan "  Checking all configured URLs (this may take a moment)..."
  echo ""

  # Determine which learning sources file to use
  local learning_file="$config_dir/learning-sources.json"
  if [[ ! -f "$learning_file" ]]; then
    learning_file="$script_dir/learning-sources.json"
  fi

  local sanity_file="$script_dir/sanity-maintenance-sources.json"

  # Check sitemaps from learning sources
  if [[ -f "$learning_file" ]] && command -v jq &>/dev/null; then
    local sitemap_count=$(jq '.sitemaps | length' "$learning_file" 2>/dev/null || echo "0")
    echo_blue "  📄 Learning Sources - Sitemaps ($sitemap_count total):"
    echo ""

    if [[ "$sitemap_count" -gt 0 ]]; then
      printf "  %-25s %-45s %-6s %s\n" "Name" "URL" "Status" "Notes"
      echo_gray "  ─────────────────────── ───────────────────────────────────────────── ────── ─────────────────────"

      for ((i=0; i<sitemap_count; i++)); do
        local title=$(jq -r ".sitemaps[$i].title" "$learning_file" 2>/dev/null)
        local url=$(jq -r ".sitemaps[$i].sitemap" "$learning_file" 2>/dev/null)
        local short_title="${title:0:23}"
        [[ ${#title} -gt 23 ]] && short_title="${short_title}.."
        local short_url="${url:0:43}"
        [[ ${#url} -gt 43 ]] && short_url="${short_url}.."

        if validate_sitemap "$url" 10; then
          printf "  %-25s %-45s " "$short_title" "$short_url"
          echo "💚"
          (( VALIDATION_PASSED++ )) || true
        else
          printf "  %-25s %-45s " "$short_title" "$short_url"
          echo "💔  Update or remove"
          (( VALIDATION_FAILED++ )) || true
        fi
      done
    else
      validation_info "No sitemaps configured"
    fi

    echo ""
    local static_count=$(jq '.static | length' "$learning_file" 2>/dev/null || echo "0")
    echo_blue "  🔗 Learning Sources - Static URLs ($static_count total):"
    echo ""

    if [[ "$static_count" -gt 0 ]]; then
      printf "  %-25s %-45s %-6s %s\n" "Name" "URL" "Status" "Notes"
      echo_gray "  ─────────────────────── ───────────────────────────────────────────── ────── ─────────────────────"

      for ((i=0; i<static_count; i++)); do
        local title=$(jq -r ".static[$i].title" "$learning_file" 2>/dev/null)
        local url=$(jq -r ".static[$i].url" "$learning_file" 2>/dev/null)
        local short_title="${title:0:23}"
        [[ ${#title} -gt 23 ]] && short_title="${short_title}.."
        local short_url="${url:0:43}"
        [[ ${#url} -gt 43 ]] && short_url="${short_url}.."

        if validate_url "$url" 10; then
          printf "  %-25s %-45s " "$short_title" "$short_url"
          echo "💚"
          (( VALIDATION_PASSED++ )) || true
        else
          printf "  %-25s %-45s " "$short_title" "$short_url"
          echo "💔  Update or remove"
          (( VALIDATION_FAILED++ )) || true
        fi
      done
    else
      validation_info "No static URLs configured"
    fi
  fi

  # Check sanity maintenance URLs
  if [[ -f "$sanity_file" ]] && command -v jq &>/dev/null; then
    echo ""

    # Count total URLs
    local total_sanity=$(jq '[.categories[] | length] | add' "$sanity_file" 2>/dev/null || echo "0")
    echo_blue "  🤪 Sanity Maintenance Sources ($total_sanity total):"
    echo ""

    # Get all categories
    local categories=$(jq -r '.categories | keys[]' "$sanity_file" 2>/dev/null)

    printf "  %-25s %-45s %-6s %s\n" "Name" "URL" "Status" "Notes"
    echo_gray "  ─────────────────────── ───────────────────────────────────────────── ────── ─────────────────────"

    for category in ${(f)categories}; do
      local url_count=$(jq ".categories[\"$category\"] | length" "$sanity_file" 2>/dev/null || echo "0")

      for ((i=0; i<url_count; i++)); do
        local title=$(jq -r ".categories[\"$category\"][$i].title" "$sanity_file" 2>/dev/null)
        local url=$(jq -r ".categories[\"$category\"][$i].url" "$sanity_file" 2>/dev/null)
        local display_name="$category: $title"
        local short_name="${display_name:0:23}"
        [[ ${#display_name} -gt 23 ]] && short_name="${short_name}.."
        local short_url="${url:0:43}"
        [[ ${#url} -gt 43 ]] && short_url="${short_url}.."

        if validate_url "$url" 10; then
          printf "  %-25s %-45s " "$short_name" "$short_url"
          echo "💚"
          (( VALIDATION_PASSED++ )) || true
        else
          printf "  %-25s %-45s " "$short_name" "$short_url"
          echo "💔  Update JSON"
          (( VALIDATION_FAILED++ )) || true
        fi
      done
    done
  fi
}

doctor_print_summary() {
  local script_dir="$1"

  echo ""
  echo_cyan "════════════════════════════════════════════════════════════════"
  echo_cyan "  📊 Diagnostics Summary"
  echo_cyan "════════════════════════════════════════════════════════════════"
  echo ""

  local total=$((VALIDATION_PASSED + VALIDATION_FAILED + VALIDATION_WARNED))

  echo_green "  Passed:   $VALIDATION_PASSED"
  if [[ $VALIDATION_FAILED -gt 0 ]]; then
    echo_red "  Failed:   $VALIDATION_FAILED"
  else
    echo "  Failed:   0"
  fi
  if [[ $VALIDATION_WARNED -gt 0 ]]; then
    echo_yellow "  Warnings: $VALIDATION_WARNED"
  else
    echo "  Warnings: 0"
  fi
  echo_cyan "  ─────────────────"
  echo "  Total:    $total"
  echo ""

  if [[ $VALIDATION_FAILED -eq 0 ]]; then
    if [[ $VALIDATION_WARNED -eq 0 ]]; then
      echo_green "  💚 All checks passed! Your system is ready."

      # Easter egg: Show celebration GIF in iTerm2
      local party_gif="$script_dir/assets/party.gif"
      if [[ -f "$party_gif" ]] && [[ "$TERM_PROGRAM" == "iTerm.app" || "$LC_TERMINAL" == "iTerm2" ]]; then
        echo ""
        printf '\033]1337;File=inline=1;width=30;height=auto;preserveAspectRatio=1:%s\a' "$(base64 < "$party_gif")"
        echo ""
      fi
    else
      echo_yellow "  ⚠ Checks passed with warnings. Some optional features may be limited."
    fi
  else
    echo_red "  ❌ Some checks failed. Please address the issues above."
  fi
  echo ""

  return $VALIDATION_FAILED
}
