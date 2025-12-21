#!/usr/bin/env zsh

###############################################################################
# View Helper Functions
#
# Provides reusable view/display helper functions used across modules:
# - Safe display with fallback values
# - String truncation for UI formatting
# - Text formatting utilities
###############################################################################

###############################################################################
# safe_display - Display a value with fallback for null/empty
#
# Returns the fallback value if the input is null, "null" string, or empty.
# Otherwise returns the original value.
#
# Usage: safe_display "$value" "$fallback"
# Example: safe_display "$api_response" "N/A"
###############################################################################
safe_display() {
  local value="$1"
  local fallback="${2:-N/A}"

  if [ -z "$value" ] || [ "$value" = "null" ]; then
    echo "$fallback"
  else
    echo "$value"
  fi
}

###############################################################################
# truncate_string - Truncate long strings with ellipsis
#
# Truncates strings that exceed max_length, appending ".." to indicate truncation.
# Useful for displaying long text in fixed-width terminal output.
#
# Usage: truncate_string "$text" "$max_length"
# Example: truncate_string "Very long message" 10  # Returns "Very long .."
###############################################################################
truncate_string() {
  local full_message="$1"
  local max_length="${2:-48}"

  if [[ ${#full_message} -gt $max_length ]]; then
    echo "${full_message:0:$max_length}.."
  else
    echo "$full_message"
  fi
}
