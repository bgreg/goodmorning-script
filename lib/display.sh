#!/usr/bin/env zsh

###############################################################################
# Display Functions
#
# Handles all information display and presentation:
# - Banner and greeting
# - Weather forecasts
# - Historical events
# - Calendar and reminders
# - Email notifications
# - PostgreSQL documentation suggestions
# - AI-powered learning tips
###############################################################################

show_banner() {
  echo_green ""
  if [ -f "$BANNER_FILE" ]; then
    echo_green "$(cat "$BANNER_FILE")"
  else
    echo_green "========================================"
    echo_green "  Good Morning ${USER_NAME}!"
    echo_green "========================================"
  fi
  echo ""
  echo_cyan "╔════════════════════════════════════════════════════════════╗"
  echo_cyan "║                                                            ║"
  echo_cyan "║               ✨  YOUR DAILY BRIEFING  ✨                  ║"
  echo_cyan "║                                                            ║"
  echo_cyan "╚════════════════════════════════════════════════════════════╝"
  echo ""
}

show_weather() {
  print_section "🌤️  Weather:" "yellow"
  local weather=$(fetch_with_spinner "Fetching weather..." curl -s --max-time 10 "wttr.in/?format=3")
  if [ -n "$weather" ]; then
    echo "$weather"
  else
    echo "Weather unavailable"
  fi
  echo ""
}

show_history() {
  print_section "📖 On This Day in History:" "yellow"
  local month
  local day
  month=$(date +%m)
  day=$(date +%d)

  if ! [[ "$month" =~ ^(0[1-9]|1[0-2])$ ]] || ! [[ "$day" =~ ^(0[1-9]|[12][0-9]|3[01])$ ]]; then
    echo "Date validation failed" >&2
    echo ""
    return 1
  fi

  if command_exists jq; then
    local api_url="https://en.wikipedia.org/api/rest_v1/feed/onthisday/events/${month}/${day}"
    local history_data=$(fetch_with_spinner "Fetching history..." curl -s --max-time 10 "$api_url")
    if [ -n "$history_data" ]; then
      # Remove control characters that break jq parsing
      local cleaned_data=$(printf '%s' "$history_data" | LC_ALL=C tr -d '\000-\037')
      printf '%s' "$cleaned_data" | jq -r '.events[:'${MAX_HISTORY_EVENTS}'] | .[] | "  • \(.year): \(.text)"' 2>> "$LOG_FILE" || echo "Historical events unavailable"
    else
      echo "Historical events unavailable"
    fi
  else
    show_setup_message "Install jq for Wikipedia history: brew install jq"
  fi
  echo ""
}

show_calendar() {
  print_section "📅 Today's Calendar:" "yellow"
  if command_exists icalBuddy; then
    local events=$(fetch_with_spinner "Fetching calendar..." icalBuddy -n -nc -iep "title,datetime" -b "" eventsToday)
    if [ -z "$events" ]; then
      echo "No events today"
    else
      echo "$events"
    fi
  else
    show_setup_message "Install icalBuddy for calendar integration: brew install ical-buddy"
  fi
  echo ""
}

show_reminders() {
  print_section "✅ Reminders:" "yellow"
  if command_exists icalBuddy; then
    local reminders=$(fetch_with_spinner "Fetching reminders..." icalBuddy -n -nc -b "" tasksDueBefore:today+1)
    reminders=$(echo "$reminders" | head -"$MAX_REMINDERS")
    if [ -z "$reminders" ]; then
      echo "No reminders due today"
    else
      echo "$reminders"
    fi
  else
    local reminder_count=$(fetch_with_spinner "Fetching reminders..." osascript "$SCRIPT_DIR/lib/apple_script/count_reminders.scpt")
    if [ -n "$reminder_count" ] && [[ "$reminder_count" =~ ^[0-9]+$ ]] && [ "$reminder_count" -gt 0 ]; then
      echo "You have ${reminder_count} incomplete reminders"
    else
      echo "No incomplete reminders"
    fi
  fi
  echo ""
}

show_github_notifications() {
  print_section "🐙 GitHub Notifications:" "yellow"

  if ! command_exists gh; then
    show_setup_message "Install GitHub CLI for notifications: brew install gh"
    echo ""
    return 0
  fi

  if ! gh auth status &>/dev/null; then
    show_setup_message "Authenticate with GitHub CLI: gh auth login"
    echo ""
    return 0
  fi

  local notifications
  notifications=$(fetch_with_spinner "Fetching GitHub notifications..." gh api notifications --jq 'length' 2>> "$LOG_FILE")

  if [ $? -ne 0 ] || [ -z "$notifications" ] || ! [[ "$notifications" =~ ^[0-9]+$ ]]; then
    echo "Unable to fetch GitHub notifications"
    echo ""
    return 0
  fi

  if [ "$notifications" -eq 0 ]; then
    echo "No unread notifications"
  else
    echo "You have ${notifications} unread notifications"

    local notification_list
    notification_list=$(gh api notifications --jq '.[:'"${MAX_GITHUB_NOTIFICATIONS:-5}"'] | .[] | "  • \(.subject.type): \(.subject.title) (\(.repository.name))"' 2>> "$LOG_FILE")

    if [ -n "$notification_list" ]; then
      echo "$notification_list"
    fi

    local pr_reviews
    pr_reviews=$(gh api notifications --jq '[.[] | select(.subject.type == "PullRequest" and .reason == "review_requested")] | length' 2>> "$LOG_FILE")
    if [ -n "$pr_reviews" ] && [ "$pr_reviews" -gt 0 ]; then
      echo_cyan "  → ${pr_reviews} PR(s) awaiting your review"
    fi
  fi
  echo ""
}

show_alias_suggestions() {
  print_section "⌨️  Alias Suggestions:" "yellow"

  local shell_history_file="${HISTFILE:-$HOME/.zsh_history}"

  if [[ ! -f "$shell_history_file" ]]; then
    echo "  History file not found"
    echo ""
    return 0
  fi

  local current_aliases_file=$(mktemp)
  local frequent_commands_file=$(mktemp)

  _cleanup_alias_temp_files() {
    rm -f "$current_aliases_file" "$frequent_commands_file"
  }
  trap _cleanup_alias_temp_files EXIT INT TERM

  alias > "$current_aliases_file" 2>/dev/null

  (
    export LC_ALL=C
    sed 's/^: [0-9]*:[0-9]*;//' "$shell_history_file" 2>/dev/null | \
      awk '{
        gsub(/^ +| +$/, "")
        # Skip if too short, starts with special chars, or looks like JSON/data
        if (length($0) > 10 && /^[a-zA-Z._\/~]/ && !/^["\047{}\[\]]/) print
      }' | \
      sort 2>/dev/null | uniq -c | sort -rn | head -20
  ) > "$frequent_commands_file"

  local suggestions_output=""
  local displayed_count=0
  local max_suggestions=10
  local max_command_display_length=45

  while IFS= read -r frequency_line; do
    [[ $displayed_count -ge $max_suggestions ]] && break

    local usage_count="${frequency_line%%[!0-9 ]*}"
    usage_count="${usage_count// /}"
    local full_command="${frequency_line#*[0-9] }"
    full_command="${full_command#"${full_command%%[![:space:]]*}"}"

    [[ -z "$full_command" ]] && continue

    local matching_alias=""
    matching_alias=$(grep -F "='$full_command'" "$current_aliases_file" 2>/dev/null | head -1 | cut -d= -f1)

    if [[ -z "$matching_alias" ]]; then
      local command_prefix="${full_command%% *} ${${full_command#* }%% *}"
      matching_alias=$(grep -F "='$command_prefix" "$current_aliases_file" 2>/dev/null | head -1 | cut -d= -f1)
    fi

    local truncated_command="${full_command:0:$max_command_display_length}"

    if [[ -n "$matching_alias" ]]; then
      suggestions_output+=$(printf "  %4d×  %-45s → use '%s'\n" "$usage_count" "$truncated_command" "$matching_alias")
    else
      # Generate suggested alias from first letters of first 3 words
      local words=(${(z)full_command})
      local suggested_alias="${words[1]:0:1}${words[2]:0:1}${words[3]:0:1}"
      suggested_alias="${suggested_alias// /}"
      [[ ${#suggested_alias} -lt 2 ]] && suggested_alias="${full_command:0:3}"
      suggestions_output+=$(printf "  %4d×  %-45s → add '%s'\n" "$usage_count" "$truncated_command" "$suggested_alias")
    fi
    suggestions_output+=$'\n'
    ((displayed_count++))
  done < "$frequent_commands_file"

  _cleanup_alias_temp_files
  trap - EXIT INT TERM

  if [[ -n "$suggestions_output" ]]; then
    echo "$suggestions_output"
  else
    echo "  No frequently used long commands found"
  fi

  echo ""
}

show_common_typos() {
  print_section "🔤 Common Typos Detected:" "yellow"

  local shell_history_file="${HISTFILE:-$HOME/.zsh_history}"

  if [[ ! -f "$shell_history_file" ]]; then
    echo "  History file not found"
    echo ""
    return 0
  fi

  # Common command misspellings and their corrections
  local -A typo_corrections=(
    [gti]="git"
    [gi]="git"
    [got]="git"
    [gut]="git"
    [sl]="ls"
    [l]="ls"
    [lls]="ls"
    [ks]="ls"
    [cta]="cat"
    [act]="cat"
    [tac]="cat"
    [cd..]="cd .."
    [cd..]=cd\ ..
    [gerp]="grep"
    [grpe]="grep"
    [grrp]="grep"
    [mkdri]="mkdir"
    [mkdr]="mkdir"
    [mdir]="mkdir"
    [rmdir]="rm -r"
    [sudp]="sudo"
    [suod]="sudo"
    [sduo]="sudo"
    [pyhton]="python"
    [pytohn]="python"
    [pythno]="python"
    [nmp]="npm"
    [npmi]="npm i"
    [dokcer]="docker"
    [dcoker]="docker"
    [docekr]="docker"
    [claer]="clear"
    [clera]="clear"
    [cealr]="clear"
    [eixt]="exit"
    [exti]="exit"
    [eit]="exit"
    [ehco]="echo"
    [ecoh]="echo"
    [vmi]="vim"
    [ivm]="vim"
    [nano]="nano"
    [naon]="nano"
  )

  local typos_found=""
  local typo_count=0
  local max_typos=10

  # Parse history and look for typos
  local history_commands=$(sed 's/^: [0-9]*:[0-9]*;//' "$shell_history_file" 2>/dev/null | \
    awk '{print $1}' | sort | uniq -c | sort -rn)

  while IFS= read -r line; do
    [[ $typo_count -ge $max_typos ]] && break
    [[ -z "$line" ]] && continue

    local count="${line%%[!0-9 ]*}"
    count="${count// /}"
    local cmd="${line#*[0-9] }"
    cmd="${cmd#"${cmd%%[![:space:]]*}"}"

    # Check if this command is a known typo
    if [[ -n "${typo_corrections[$cmd]}" ]]; then
      local correction="${typo_corrections[$cmd]}"
      typos_found+=$(printf "  %4d×  %-15s → %s\n" "$count" "$cmd" "$correction")
      typos_found+=$'\n'
      ((typo_count++))
    fi
  done <<< "$history_commands"

  if [[ -n "$typos_found" ]]; then
    echo "$typos_found"
    echo_gray "  Tip: Add aliases to auto-correct these typos"
  else
    echo "  No common typos detected - great typing!"
  fi

  echo ""
}

show_system_info() {
  print_section "💻 System Information:" "yellow"

  # macOS version
  local macos_version=$(sw_vers -productVersion 2>/dev/null)
  local macos_name=$(sw_vers -productName 2>/dev/null)
  if [ -n "$macos_version" ]; then
    echo "  macOS: $macos_name $macos_version"
  fi

  # Safari version
  local safari_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" /Applications/Safari.app/Contents/Info.plist 2>/dev/null)
  if [ -n "$safari_version" ]; then
    echo "  Safari: $safari_version"
  fi

  # Uptime (time since last reboot)
  local uptime_info=$(uptime | sed 's/.*up //' | sed 's/,.*//' | sed 's/^[ \t]*//')
  if [ -n "$uptime_info" ]; then
    echo "  Uptime: $uptime_info"
  fi

  # Disk space
  local disk_info=$(df -h / 2>/dev/null | awk 'NR==2 {print $4 " free of " $2}')
  if [ -n "$disk_info" ]; then
    echo "  Disk: $disk_info"
  fi

  # Memory usage
  local mem_info=$(vm_stat 2>/dev/null | awk '
    /Pages free/ {free=$3}
    /Pages active/ {active=$3}
    /Pages inactive/ {inactive=$3}
    /Pages speculative/ {spec=$3}
    /Pages wired/ {wired=$3}
    END {
      gsub(/\./, "", free); gsub(/\./, "", active); gsub(/\./, "", inactive); gsub(/\./, "", spec); gsub(/\./, "", wired)
      used = (active + wired) * 4096 / 1073741824
      total = (free + active + inactive + spec + wired) * 4096 / 1073741824
      printf "%.1fGB used of %.1fGB", used, total
    }')
  if [ -n "$mem_info" ]; then
    echo "  Memory: $mem_info"
  fi

  # Battery status (for laptops)
  local battery_info=$(pmset -g batt 2>/dev/null | grep -o '[0-9]*%' | head -1)
  local charging_status=$(pmset -g batt 2>/dev/null | grep -o "'.*'" | tr -d "'")
  if [ -n "$battery_info" ]; then
    if [ -n "$charging_status" ]; then
      echo "  Battery: $battery_info ($charging_status)"
    else
      echo "  Battery: $battery_info"
    fi
  fi

  echo ""
}

_gather_git_context() {
  local context=""

  for project_dir in ${(s.:.)PROJECT_DIRS}; do
    if [ ! -d "$project_dir" ] || [ ! -r "$project_dir" ]; then
      continue
    fi

    local recent_commits=$(timeout "$GIT_SCAN_TIMEOUT" find "$project_dir" -maxdepth "$GIT_SCAN_DEPTH" -name ".git" -type d 2>> "$LOG_FILE" | head -"$MAX_REPOS_TO_SCAN" | while read -r gitdir; do
      local repo_dir=$(dirname "$gitdir")
      cd "$repo_dir" 2>> "$LOG_FILE" || continue

      local author_email=$(git config user.email 2>> "$LOG_FILE")
      if [ -z "$author_email" ]; then
        continue
      fi

      if [[ ! "$author_email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        continue
      fi

      local commits=$(git log --since="${GIT_LOOKBACK_DAYS} days ago" --pretty=format:"%s" \
        --author="$author_email" 2>> "$LOG_FILE" | head -"$MAX_COMMITS_PER_REPO")
      if [ -n "$commits" ]; then
        echo "Recent commits in $(basename "$repo_dir"):"
        echo "$commits"
      fi
    done | head -20)

    context="${context}${recent_commits}"
  done

  echo "$context"
}

_generate_and_display_tip() {
  local context="$1"
  local prompt_type="$2"
  local claude_tip
  local prompt

  if [ "$prompt_type" = "personalized" ]; then
    local sanitized_context
    sanitized_context=$(printf '%s' "$context" | tr -d '\000-\031\177-\237' | head -c "$MAX_CONTEXT_LENGTH")

    prompt="Based on my recent development work:

${sanitized_context}

Provide ONE short, actionable learning tip (2-3 sentences) about a concept, pattern, or technique related to my recent work.

IMPORTANT REQUIREMENTS:
1. Only provide factual, verifiable information from official documentation or well-known technical resources
2. You MUST end with a blank line followed by 'Source: [Title] - ' and then a REAL, working URL that I can click
3. Do NOT make up sources or URLs - only use actual documentation sites you know exist
4. If you cannot provide a real URL, simply provide a general software engineering tip with a real URL instead"
  else
    prompt="Give me ONE short, actionable software engineering learning tip (2-3 sentences) that would be valuable for a developer.

IMPORTANT REQUIREMENTS:
1. Only provide factual, verifiable information from official documentation or well-known technical resources
2. You MUST end with a blank line followed by 'Source: [Title] - ' and then a REAL, working URL that I can click
3. Do NOT make up sources or URLs - only use actual documentation sites you know exist"
  fi

  claude_tip=$(fetch_with_spinner "Getting learning tip..." claude -p "$prompt")

  if [ -n "$claude_tip" ]; then
    echo_green "${claude_tip}"
  else
    if [ "$prompt_type" = "personalized" ]; then
      echo "Unable to generate personalized tip right now"
    else
      echo "Claude learning tips unavailable"
    fi
  fi
}

_show_claude_install_message() {
  show_setup_message "Install Claude Code to get personalized learning tips!"
}

show_learning_tips() {
  print_section "🎓 Your Personalized Learning Tip:"

  if command_exists claude; then
    local context
    context=$(_gather_git_context)

    if [ -n "$context" ]; then
      _generate_and_display_tip "$context" "personalized"
    else
      _generate_and_display_tip "" "general"
    fi
  else
    _show_claude_install_message
  fi

  echo ""
}
