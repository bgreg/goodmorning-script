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
    echo_green "╔════════════════════════════════════╗"
    echo_green "║      Good Morning ${USER_NAME}!      ║"
    echo_green "╚════════════════════════════════════╝"
  fi
  print_section "Your Daily Briefing"
  echo ""
}

show_weather() {
  echo_yellow "🌤️  Weather:"
  curl -s "wttr.in/?format=3" 2>> "$LOG_FILE" || echo "Weather unavailable"
  echo ""
}

show_history() {
  echo_yellow "📖 On This Day in History:"
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
    curl -s "https://en.wikipedia.org/api/rest_v1/feed/onthisday/events/${month}/${day}" 2>> "$LOG_FILE" | \
      jq -r ".events[:${MAX_HISTORY_EVENTS}] | .[] | \"  • \(.year): \(.text)\"" 2>> "$LOG_FILE" || echo "Historical events unavailable"
  else
    show_setup_message "Install jq for Wikipedia history: brew install jq"
  fi
  echo ""
}

show_calendar() {
  echo_yellow "📅 Today's Calendar:"
  if command_exists icalBuddy; then
    local events=$(icalBuddy -n -nc -iep "title,datetime" -b "" eventsToday 2>> "$LOG_FILE")
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
  echo_yellow "✅ Reminders:"
  if command_exists icalBuddy; then
    local reminders=$(icalBuddy -n -nc -b "" tasksDueBefore:today+1 2>> "$LOG_FILE" | head -"$MAX_REMINDERS")
    if [ -z "$reminders" ]; then
      echo "No reminders due today"
    else
      echo "$reminders"
    fi
  else
    local reminder_count=$(osascript "$SCRIPT_DIR/lib/apple_script/count_reminders.scpt" 2>> "$LOG_FILE")
    if [ -n "$reminder_count" ] && [[ "$reminder_count" =~ ^[0-9]+$ ]] && [ "$reminder_count" -gt 0 ]; then
      echo "You have ${reminder_count} incomplete reminders"
    else
      echo "No incomplete reminders"
    fi
  fi
  echo ""
}

show_email() {
  echo_yellow "📧 Recent Unread Emails:"

  if ! osascript "$SCRIPT_DIR/lib/apple_script/check_mail_running.scpt" 2>> "$LOG_FILE" | grep -q "true"; then
    show_setup_message "Mail.app is not running"
    echo ""
    return 0
  fi

  local email_count
  email_count=$(osascript "$SCRIPT_DIR/lib/apple_script/count_unread_emails.scpt" 2>> "$LOG_FILE")

  if [ $? -ne 0 ] || [ -z "$email_count" ] || ! [[ "$email_count" =~ ^[0-9]+$ ]]; then
    show_setup_message "Unable to access Mail.app (check permissions in System Settings > Privacy)"
    echo ""
    return 0
  fi

  if [ "$email_count" -eq 0 ]; then
    echo "No unread emails"
  else
    echo "You have ${email_count} unread emails"

    local email_list
    email_list=$(osascript "$SCRIPT_DIR/lib/apple_script/get_recent_emails.scpt" "$MAX_EMAILS" 2>> "$LOG_FILE")

    if [ -n "$email_list" ]; then
      echo "$email_list" | while IFS='|' read -r subject sender; do
        [ -n "$subject" ] && echo "  • ${subject} - ${sender}"
      done
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
  local claude_tip_file

  claude_tip_file=$(mktemp "$CLAUDE_TIP_PATTERN") || {
    echo "Unable to create temp file for Claude tip" >&2
    echo ""
    return 1
  }

  TEMP_FILES+=("$claude_tip_file")

  if [ "$prompt_type" = "personalized" ]; then
    local sanitized_context
    sanitized_context=$(printf '%s' "$context" | tr -d '\000-\031\177-\237' | head -c "$MAX_CONTEXT_LENGTH")

    timeout "${SPINNER_TIMEOUT}" claude -p "Based on my recent development work:

${sanitized_context}

Provide ONE short, actionable learning tip (2-3 sentences) about a concept, pattern, or technique related to my recent work.

IMPORTANT REQUIREMENTS:
1. Only provide factual, verifiable information from official documentation or well-known technical resources
2. You MUST end with a blank line followed by 'Source: [Title] - ' and then a REAL, working URL that I can click
3. Do NOT make up sources or URLs - only use actual documentation sites you know exist
4. If you cannot provide a real URL, simply provide a general software engineering tip with a real URL instead" \
      < /dev/null > "$claude_tip_file" 2>&1
  else
    timeout "${SPINNER_TIMEOUT}" claude -p "Give me ONE short, actionable software engineering learning tip (2-3 sentences) that would be valuable for a developer.

IMPORTANT REQUIREMENTS:
1. Only provide factual, verifiable information from official documentation or well-known technical resources
2. You MUST end with a blank line followed by 'Source: [Title] - ' and then a REAL, working URL that I can click
3. Do NOT make up sources or URLs - only use actual documentation sites you know exist" \
      < /dev/null > "$claude_tip_file" 2>&1
  fi

  local claude_tip=$(cat "$claude_tip_file" 2>> "$LOG_FILE")

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
      echo_yellow "Generating personalized tip..."
      _generate_and_display_tip "$context" "personalized"
    else
      echo_yellow "Generating learning tip..."
      _generate_and_display_tip "" "general"
    fi
  else
    _show_claude_install_message
  fi

  echo ""
}
