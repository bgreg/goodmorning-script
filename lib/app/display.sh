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
  show_new_line
  echo_cyan "╔════════════════════════════════════════════════════════════╗"
  echo_cyan "║                                                            ║"
  echo_cyan "║               ✨  YOUR DAILY BRIEFING  ✨                  ║"
  echo_cyan "║                                                            ║"
  echo_cyan "╚════════════════════════════════════════════════════════════╝"
  show_new_line
}

show_weather() {
  print_section "🌤️  Weather:" "yellow"
  local location="${GOODMORNING_WEATHER_LOCATION:-}"

  if [ -z "$location" ]; then
    show_setup_message "Set GOODMORNING_WEATHER_LOCATION to your city (e.g., San_Francisco)"
    show_new_line
    return 0
  fi

  # Validate location to avoid unsafe characters in the URL
  if ! [[ "$location" =~ ^[A-Za-z0-9_-]+$ ]]; then
    echo "Invalid weather location: '$location'" >&2
    echo "Use only letters, numbers, underscores, and hyphens (e.g., San_Francisco)." >&2
    show_new_line
    return 1
  fi
  local url="wttr.in/${location}?format=3&u"
  local weather=$(fetch_with_spinner "Fetching weather..." curl -s --max-time 10 "$url")

  if [ -n "$weather" ] && [[ "$weather" != "not found:"* ]]; then
    echo "$weather"
  else
    echo "Weather unavailable for: $location"
  fi
  show_new_line
}

show_history() {
  print_section "📖 On This Day in History:" "yellow"
  local month
  local day
  month=$(date +%m)
  day=$(date +%d)

  if ! [[ "$month" =~ ^(0[1-9]|1[0-2])$ ]] || ! [[ "$day" =~ ^(0[1-9]|[12][0-9]|3[01])$ ]]; then
    echo "Date validation failed" >&2
    show_new_line
    return 1
  fi

  if command_exists jq; then
    local api_url="https://en.wikipedia.org/api/rest_v1/feed/onthisday/events/${month}/${day}"
    local history_data=$(fetch_with_spinner "Fetching history..." curl -s --max-time 10 "$api_url")
    if [ -n "$history_data" ]; then
      # Remove control characters that break jq parsing
      local cleaned_data=$(printf '%s' "$history_data" | LC_ALL=C tr -d '\000-\037')
      local jq_filter='.events[:'${MAX_HISTORY_EVENTS}'] | .[] | "  • \(.year): \(.text)"'
      printf '%s' "$cleaned_data" | jq -r "$jq_filter" 2>> "$LOG_FILE" || echo "Historical events unavailable"
    else
      echo "Historical events unavailable"
    fi
  else
    show_setup_message "Install jq for Wikipedia history: brew install jq"
  fi
  show_new_line
}

show_calendar() {
  local calendar_count=$(_fetch_count_with_timeout "$SCRIPT_DIR/lib/app/apple_scripts/count_calendar.scpt")
  print_section "📅 Today's Calendar ($calendar_count):" "yellow"
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
  show_new_line
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
    local scpt="$SCRIPT_DIR/lib/app/apple_scripts/count_reminders.scpt"
    local reminder_count=$(fetch_with_spinner "Fetching reminders..." osascript "$scpt")
    if [ -n "$reminder_count" ] && [[ "$reminder_count" =~ ^[0-9]+$ ]] && [ "$reminder_count" -gt 0 ]; then
      echo "You have ${reminder_count} incomplete reminders"
    else
      echo "No incomplete reminders"
    fi
  fi
  show_new_line
}

show_github_notifications() {
  print_section "🐙 GitHub Notifications:" "yellow"

  if ! command_exists gh; then
    show_setup_message "Install GitHub CLI for notifications: brew install gh"
    show_new_line
    return 0
  fi

  if ! gh auth status &>/dev/null; then
    show_setup_message "Authenticate with GitHub CLI: gh auth login"
    show_new_line
    return 0
  fi

  local notifications
  notifications=$(fetch_with_spinner "Fetching GitHub notifications..." \
    gh api notifications --jq 'length' 2>> "$LOG_FILE")


  if [ $? -ne 0 ] || [ -z "$notifications" ] || ! [[ "$notifications" =~ ^[0-9]+$ ]]; then
    echo "Unable to fetch GitHub notifications"
    show_new_line
    return 0
  fi

  if [ "$notifications" -eq 0 ]; then
    echo "No unread notifications"
  else
    echo "You have ${notifications} unread notifications"

    local max="${MAX_GITHUB_NOTIFICATIONS:-5}"
    local jq_filter='.[:'"$max"'] | .[] | "  • \(.subject.type): \(.subject.title) (\(.repository.name))"'
    local notification_list=$(gh api notifications --jq "$jq_filter" 2>> "$LOG_FILE")

    if [ -n "$notification_list" ]; then
      echo "$notification_list"
    fi

    local pr_filter='[.[] | select(.subject.type == "PullRequest" and .reason == "review_requested")] | length'
    local pr_reviews=$(gh api notifications --jq "$pr_filter" 2>> "$LOG_FILE")
    if [ -n "$pr_reviews" ] && [ "$pr_reviews" -gt 0 ]; then
      echo_cyan "  → ${pr_reviews} PR(s) awaiting your review"
    fi
  fi
  show_new_line
}


_validate_author_email() {
  local email="$1"
  [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

_get_repo_commits() {
  local gitdir="$1"
  local repo_dir=$(dirname "$gitdir")

  cd "$repo_dir" 2>> "$LOG_FILE" || return 1

  local author_email=$(git config user.email 2>> "$LOG_FILE")
  [ -z "$author_email" ] && return 1
  _validate_author_email "$author_email" || return 1

  local commits=$(git log --since="${GIT_LOOKBACK_DAYS} days ago" --pretty=format:"%s" \
    --author="$author_email" 2>> "$LOG_FILE" | head -"$MAX_COMMITS_PER_REPO")

  if [ -n "$commits" ]; then
    echo "Recent commits in $(basename "$repo_dir"):"
    echo "$commits"
  fi
}

_gather_git_context() {
  local context=""

  for project_dir in ${(s.:.)PROJECT_DIRS}; do
    [ ! -d "$project_dir" ] || [ ! -r "$project_dir" ] && continue

    local find_cmd="find $project_dir -maxdepth $GIT_SCAN_DEPTH -name .git -type d"
    local recent_commits=$(timeout "$GIT_SCAN_TIMEOUT" sh -c "$find_cmd" 2>> "$LOG_FILE" | \
      head -"$MAX_REPOS_TO_SCAN" | while read -r gitdir; do _get_repo_commits "$gitdir"; done | head -20)

    context="${context}${recent_commits}"
  done

  echo "$context"
}

_build_learning_prompt() {
  local context="$1"
  local prompt_type="$2"

  if [ "$prompt_type" = "personalized" ]; then
    local sanitized_context
    sanitized_context=$(printf '%s' "$context" | tr -d '\000-\031\177-\237' | head -c "$MAX_CONTEXT_LENGTH")

    cat <<EOF
Based on my recent development work:

${sanitized_context}

Provide ONE short, actionable learning tip (2-3 sentences) about a concept, pattern, or technique related to my recent work.

IMPORTANT REQUIREMENTS:
1. Only provide factual, verifiable information from official documentation or well-known technical resources
2. You MUST end with a blank line followed by 'Source: [Title] - ' and then a REAL, working URL that I can click
3. Do NOT make up sources or URLs - only use actual documentation sites you know exist
4. If you cannot provide a real URL, simply provide a general software engineering tip with a real URL instead
EOF
  else
    cat <<EOF
Give me ONE short, actionable software engineering learning tip (2-3 sentences) that would be valuable for a developer.

IMPORTANT REQUIREMENTS:
1. Only provide factual, verifiable information from official documentation or well-known technical resources
2. You MUST end with a blank line followed by 'Source: [Title] - ' and then a REAL, working URL that I can click
3. Do NOT make up sources or URLs - only use actual documentation sites you know exist
EOF
  fi
}

_generate_and_display_tip() {
  local context="$1"
  local prompt_type="$2"
  local claude_tip
  local prompt=$(_build_learning_prompt "$context" "$prompt_type")

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

  show_new_line
}
