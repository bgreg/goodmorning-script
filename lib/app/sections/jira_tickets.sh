#!/usr/bin/env zsh

register_section "jira_tickets" --tools "curl" "jq" --network

_validate_jira_setup() {
  if [ -z "$JIRA_DOMAIN" ]; then
    show_setup_message "Set GOODMORNING_JIRA_DOMAIN (e.g., yourcompany.atlassian.net)"
    return 1
  fi

  if [ -z "$JIRA_EMAIL" ]; then
    show_setup_message "Set GOODMORNING_JIRA_EMAIL to your Jira account email"
    return 1
  fi

  if [ -z "$JIRA_TOKEN_FILE" ] || [ ! -f "$JIRA_TOKEN_FILE" ]; then
    show_setup_message "Set GOODMORNING_JIRA_TOKEN_FILE to your API token file path"
    return 1
  fi

  return 0
}

_read_jira_token() {
  local token=$(cat "$JIRA_TOKEN_FILE" 2>>"$LOG_FILE" | tr -d '[:space:]')
  if [ -z "$token" ]; then
    return 1
  fi
  printf '%s' "$token"
}

_build_jira_auth_header() {
  local token="$1"
  printf '%s:%s' "$JIRA_EMAIL" "$token" | base64 | tr -d '\n'
}

_build_jira_jql() {
  echo "assignee = currentUser() AND statusCategory != Done ORDER BY status ASC, updated DESC"
}

_parse_jira_tickets() {
  local api_response="$1"
  printf '%s' "$api_response" | jq -r '
    .issues[] |
    {
      key: .key,
      summary: .fields.summary,
      status: .fields.status.name,
      category: .fields.status.statusCategory.name
    } | @json
  ' 2>>"$LOG_FILE"
}

_get_status_categories() {
  local parsed_tickets="$1"
  local preferred_order=("In Progress" "To Do")
  local found_categories=()

  for category in "${preferred_order[@]}"; do
    if echo "$parsed_tickets" | grep -q "\"category\":\"$category\""; then
      found_categories+=("$category")
    fi
  done

  printf '%s\n' "${found_categories[@]}"
}

_display_jira_ticket_group() {
  local category="$1"
  local tickets="$2"

  local count=$(echo "$tickets" | grep -c "\"category\":\"$category\"")
  echo_cyan "${category} (${count}):"
  show_new_line

  echo "$tickets" | while IFS= read -r ticket_json; do
    local ticket_category=$(printf '%s' "$ticket_json" | jq -r '.category' 2>>"$LOG_FILE")
    [ "$ticket_category" != "$category" ] && continue

    local key=$(printf '%s' "$ticket_json" | jq -r '.key' 2>>"$LOG_FILE")
    local summary=$(printf '%s' "$ticket_json" | jq -r '.summary' 2>>"$LOG_FILE")

    echo "  • ${key}: ${summary}"
    echo "    🔗 https://${JIRA_DOMAIN}/browse/${key}"
    show_new_line
  done
}

show_jira_tickets() {
  print_section "🎫 Jira Tickets:" "yellow"

  _validate_jira_setup || return 0

  local token=$(_read_jira_token)
  if [ -z "$token" ]; then
    echo "Unable to read Jira API token"
    show_new_line
    return 0
  fi

  local jql=$(_build_jira_jql)
  local max_tickets="${MAX_JIRA_TICKETS:-15}"
  local api_url="https://${JIRA_DOMAIN}/rest/api/3/search/jql"

  local response
  response=$(curl -s --max-time 15 \
    -u "${JIRA_EMAIL}:${token}" \
    -H "Content-Type: application/json" \
    "${api_url}?jql=$(printf '%s' "$jql" | jq -sRr @uri)&maxResults=${max_tickets}&fields=summary,status" \
    2>>"$LOG_FILE")

  if [ $? -ne 0 ] || [ -z "$response" ]; then
    echo "Unable to fetch Jira tickets"
    echo_gray "  → Check JIRA_DOMAIN, JIRA_EMAIL, and token file"
    show_new_line
    return 0
  fi

  if printf '%s' "$response" | jq -e '.errorMessages' &>/dev/null; then
    local error_msg=$(printf '%s' "$response" | jq -r '.errorMessages[0] // "Unknown error"' 2>>"$LOG_FILE")
    echo "Jira API error: ${error_msg}"
    show_new_line
    return 0
  fi

  local issue_count=$(printf '%s' "$response" | jq -r '.issues | length // 0' 2>>"$LOG_FILE")

  if [ "$issue_count" -eq 0 ] 2>/dev/null; then
    echo "No open Jira tickets assigned to you"
    show_new_line
    return 0
  fi

  local parsed=$(_parse_jira_tickets "$response")
  if [ -z "$parsed" ]; then
    echo "Unable to parse Jira response"
    show_new_line
    return 0
  fi

  local is_last=$(printf '%s' "$response" | jq -r '.isLast // true' 2>>"$LOG_FILE")
  if [ "$is_last" = "false" ]; then
    echo "Showing first ${max_tickets} tickets (more available):"
    echo_gray "  → Adjust GOODMORNING_MAX_JIRA_TICKETS in config to show more"
    show_new_line
  fi

  local categories=$(_get_status_categories "$parsed")
  echo "$categories" | while IFS= read -r category; do
    [ -z "$category" ] && continue
    _display_jira_ticket_group "$category" "$parsed"
  done
}
