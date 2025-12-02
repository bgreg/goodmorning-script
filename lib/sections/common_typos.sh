#!/usr/bin/env zsh

###############################################################################
# Common Typos Section
#
# Analyzes shell history to detect common command typos and suggests corrections
###############################################################################

# Section dependencies
SECTION_DEPS_TOOLS=(awk sort uniq grep sed)
SECTION_DEPS_NETWORK=false

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
