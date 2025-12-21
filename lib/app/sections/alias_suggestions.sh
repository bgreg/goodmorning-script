#!/usr/bin/env zsh

###############################################################################
# Alias Suggestions Section
#
# Analyzes shell history to suggest aliases for frequently used long commands
###############################################################################

register_section "alias_suggestions" --tools "awk" "sort" "uniq" "grep" "sed"

show_alias_suggestions() {
  print_section "⌨️  Alias Suggestions:" "yellow"

  local shell_history_file="${HISTFILE:-$HOME/.zsh_history}"

  if [[ ! -f "$shell_history_file" ]]; then
    echo "  History file not found"
    show_new_line
    return 0
  fi

  local current_aliases_file=$(mktemp)
  local frequent_commands_file=$(mktemp)

  cleanup_alias_temp_files() {
    rm -f "$current_aliases_file" "$frequent_commands_file"
  }
  trap cleanup_alias_temp_files EXIT INT TERM

  alias > "$current_aliases_file" 2>> "${LOG_FILE:-/dev/null}"

  (
    export LC_ALL=C
    # Strip zsh extended history format timestamps (e.g., ": TIMESTAMP:0;command")
    sed 's/^: [0-9]*:[0-9]*;//' "$shell_history_file" 2>> "${LOG_FILE:-/dev/null}" | \
      awk '
        # Filter to find meaningful, alias-worthy commands
        {
          # Trim leading and trailing whitespace
          gsub(/^ +| +$/, "")

          # Skip commands that are too short to benefit from aliasing
          is_long_enough = (length($0) > 10)

          # Must start with: letter, dot, underscore, slash, or tilde
          # (i.e., actual commands, not operators or special syntax)
          starts_with_command = /^[a-zA-Z._\/~]/

          # Skip data/JSON-like strings that may appear in history
          # Matches lines starting with: quotes, braces, or brackets
          looks_like_data = /^["'"'"'{}\[\]]/

          if (is_long_enough && starts_with_command && !looks_like_data) print
        }
      ' | \
      sort 2>> "${LOG_FILE:-/dev/null}" | uniq -c | sort -rn | head -20
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
    matching_alias=$(grep -F "='$full_command'" "$current_aliases_file" 2>> "${LOG_FILE:-/dev/null}" | head -1 | cut -d= -f1)

    if [[ -z "$matching_alias" ]]; then
      local command_prefix="${full_command%% *} ${${full_command#* }%% *}"
      matching_alias=$(grep -F "='$command_prefix" "$current_aliases_file" 2>> "${LOG_FILE:-/dev/null}" | head -1 | cut -d= -f1)
    fi

    local truncated_command="${full_command:0:$max_command_display_length}"

    if [[ -n "$matching_alias" ]]; then
      local fmt="  %4d×  %-45s → use '%s'\n"
      suggestions_output+=$(printf "$fmt" "$usage_count" "$truncated_command" "$matching_alias")
    else
      # Generate suggested alias from first letters of first 3 words
      local words=(${(z)full_command})
      local suggested_alias="${words[1]:0:1}${words[2]:0:1}${words[3]:0:1}"
      suggested_alias="${suggested_alias// /}"
      [[ ${#suggested_alias} -lt 2 ]] && suggested_alias="${full_command:0:3}"
      local fmt="  %4d×  %-45s → add '%s'\n"
      suggestions_output+=$(printf "$fmt" "$usage_count" "$truncated_command" "$suggested_alias")
    fi
    suggestions_output+=$'\n'
    ((displayed_count++))
  done < "$frequent_commands_file"

  cleanup_alias_temp_files
  trap - EXIT INT TERM

  if [[ -n "$suggestions_output" ]]; then
    echo "$suggestions_output"
  else
    echo "  No frequently used long commands found"
  fi

  show_new_line
}
