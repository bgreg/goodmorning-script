#!/usr/bin/env zsh

register_section "command_not_found" --tools "awk" "sort" "uniq" "tail"

show_command_not_found() {
  print_section "🔍 Recent Commands Not Found:" "yellow"

  local log_file="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/command-not-found.log"

  if [[ ! -f "$log_file" ]]; then
    echo "  No command-not-found log yet"
    show_new_line
    return 0
  fi

  local max_entries=10
  local results
  results=$(tail -100 "$log_file" | awk -F': ' '{print $NF}' | sort | uniq -c | sort -rn | head -$max_entries)

  if [[ -z "$results" ]]; then
    echo "  No commands logged yet"
    show_new_line
    return 0
  fi

  while IFS= read -r line; do
    local count="${line%%[!0-9 ]*}"
    count="${count// /}"
    local cmd="${line#*[0-9] }"
    cmd="${cmd#"${cmd%%[![:space:]]*}"}"
    printf "  %4d×  %s\n" "$count" "$cmd"
  done <<<"$results"

  show_new_line
}
