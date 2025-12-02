#!/usr/bin/env zsh

###############################################################################
# Work Section Template for Good Morning Script
###############################################################################
#
# This is a template for creating custom work-related sections.
# These can show project status, deployment info, on-call schedules, etc.
#
# Usage:
# 1. Copy this file to lib/app/sections/:
#    cp examples/work-section-template.sh lib/app/sections/work_status.sh
#
# 2. Edit the copied file to add your work-specific logic
#
# 3. Source it in goodmorning.sh after other sections:
#    if [ -f "$SCRIPT_DIR/lib/app/sections/work_status.sh" ]; then
#      source "$SCRIPT_DIR/lib/app/sections/work_status.sh"
#    fi
#
# 4. Call it in the main() function:
#    show_work_status
#
###############################################################################

# Section dependencies (optional)
SECTION_DEPS_TOOLS=(jq curl)      # Required CLI tools
SECTION_DEPS_NETWORK=true         # Requires internet connectivity

show_work_status() {
  print_section "💼 Work Status:" "cyan"

  # Example 1: Show current sprint info
  echo "Sprint: Sprint 47 (Week 2 of 2)"
  echo "Focus: API migration & bug fixes"
  echo ""

  # Example 2: Show on-call status
  # You could fetch this from PagerDuty API, Google Calendar, etc.
  echo "On-call: John Doe (ends Friday)"
  echo ""

  # Example 3: Show deployment status
  # You could fetch this from your CI/CD system
  echo "Production: v2.4.1 (deployed 2 hours ago)"
  echo "Staging: v2.5.0-rc1 (ready for testing)"
  echo ""

  # Example 4: Show open incidents
  # You could fetch from Jira, GitHub Issues, etc.
  local open_incidents=0
  if [ $open_incidents -gt 0 ]; then
    echo_red "⚠️  $open_incidents open incidents"
  else
    echo_green "✓ No open incidents"
  fi
  echo ""

  # Example 5: Show team availability
  # You could parse Google Calendar, Slack status, etc.
  echo "Team availability:"
  echo "  • Alice: Available"
  echo "  • Bob: Meeting until 10am"
  echo "  • Carol: OOO (back tomorrow)"
  echo ""

  # Example 6: Show your tasks for today
  # You could fetch from Jira, Asana, Linear, etc.
  echo "Your tasks today:"
  echo "  • Fix auth bug (#1234)"
  echo "  • Review PR #567"
  echo "  • Deploy staging environment"
  echo ""
}

###############################################################################
# Example: Fetching data from external APIs
###############################################################################

# Uncomment and customize for your needs:
#
# _fetch_jira_tasks() {
#   local jira_url="https://your-company.atlassian.net"
#   local api_token="$JIRA_API_TOKEN"  # Set in your config.sh
#
#   curl -s -u "your-email@example.com:$api_token" \
#     "$jira_url/rest/api/3/search?jql=assignee=currentUser()+AND+status=Open" \
#     | jq -r '.issues[] | "  • \(.fields.summary) (\(.key))"'
# }
#
# _fetch_pagerduty_oncall() {
#   local pd_token="$PAGERDUTY_API_TOKEN"  # Set in your config.sh
#
#   curl -s -H "Authorization: Token token=$pd_token" \
#     "https://api.pagerduty.com/oncalls?include[]=users" \
#     | jq -r '.oncalls[0].user.summary'
# }

###############################################################################
# Security Note
###############################################################################
#
# NEVER hardcode API tokens in this file!
# Instead, set them in your config.sh:
#
#   export JIRA_API_TOKEN="your-token-here"
#   export PAGERDUTY_API_TOKEN="your-token-here"
#
# Or use environment variables set in your ~/.zshrc
###############################################################################
