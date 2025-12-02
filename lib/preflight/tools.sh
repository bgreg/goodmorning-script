#!/usr/bin/env zsh

###############################################################################
# Tool Dependency Checks
#
# Validates required and optional command-line tools are available.
# Required tool failures should STOP execution.
# Optional tool failures should warn but continue.
###############################################################################

# Required tools for core functionality
typeset -gA REQUIRED_TOOLS=(
  [curl]=1
  [git]=1
  [jq]=1
)

# Optional tools that enable additional features
typeset -gA OPTIONAL_TOOLS=(
  [gh]="GitHub notifications and PR integration"
  [icalBuddy]="Calendar and reminders integration"
  [figlet]="Custom banner generation"
  [brew]="Homebrew package updates"
  [claude]="AI-powered learning tips"
)

###############################################################################
# check_required_tools - Verify all required tools are installed
#
# Outputs: List of found tools to stdout
# Returns: 0 if all found, 1 if any missing
###############################################################################
check_required_tools() {
  local missing=()
  local found=()

  for tool in "${(@k)REQUIRED_TOOLS}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      found+=("$tool")
      echo "$tool"
    else
      missing+=("$tool")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing required tools: ${missing[*]}" >&2
    return 1
  fi

  return 0
}

###############################################################################
# check_optional_tools - Check optional tools and report availability
#
# Outputs: List of found optional tools with descriptions
# Returns: Always 0 (optional tools don't block execution)
###############################################################################
check_optional_tools() {
  for tool in "${(@k)OPTIONAL_TOOLS}"; do
    local description="${OPTIONAL_TOOLS[$tool]}"
    if command -v "$tool" >/dev/null 2>&1; then
      echo "$tool: available ($description)"
    else
      echo "$tool: not found ($description)"
    fi
  done

  return 0
}
