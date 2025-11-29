#!/usr/bin/env zsh

###############################################################################
# Core Utility Functions
#
# Provides essential utilities used across all goodmorning modules:
# - Resource cleanup and signal handling
# - Dependency validation
# - Safe script sourcing with permission checks
# - Visual feedback (spinner) for long-running operations
###############################################################################

_cleanup() {
  local file
  local pid

  for file in "${TEMP_FILES[@]}"; do
    if [ -f "$file" ]; then
      rm -f "$file" 2>> "$LOG_FILE"
    fi
  done

  for pid in "${BACKGROUND_PIDS[@]}"; do
    if kill -0 "$pid" 2>> "$LOG_FILE"; then
      kill "$pid" 2>> "$LOG_FILE"
    fi
  done
}

# when the script exits or is interrupted, run cleanup
trap _cleanup EXIT INT TERM

###############################################################################
# Status Message Helpers
###############################################################################

echo_success() {
  echo_green "✓ $*"
}

echo_error() {
  echo_red "✗ $*"
}

echo_warning() {
  echo_yellow "⚠ $*"
}

###############################################################################
# iTerm2 Integration
###############################################################################

_iterm_mark() {
  if [[ "$TERM_PROGRAM" == "iTerm.app" || "$LC_TERMINAL" == "iTerm2" ]]; then
    if [[ -w /dev/tty ]]; then
      printf '\033]1337;SetMark\a' > /dev/tty
    else
      printf '\033]1337;SetMark\a'
    fi
  fi
}

_iterm_notify() {
  local message="$1"
  if [[ "$TERM_PROGRAM" == "iTerm.app" || "$LC_TERMINAL" == "iTerm2" ]]; then
    if [[ -w /dev/tty ]]; then
      printf '\033]9;%s\a' "$message" > /dev/tty
    else
      printf '\033]9;%s\a' "$message"
    fi
  fi
}

_iterm_set_badge() {
  local badge_text="$1"
  if [[ "$TERM_PROGRAM" == "iTerm.app" || "$LC_TERMINAL" == "iTerm2" ]]; then
    local encoded
    encoded=$(printf '%s' "$badge_text" | base64)
    if [[ -w /dev/tty ]]; then
      printf '\033]1337;SetBadgeFormat=%s\a' "$encoded" > /dev/tty
    else
      printf '\033]1337;SetBadgeFormat=%s\a' "$encoded"
    fi
  fi
}

_iterm_set_title() {
  local title="$1"
  if [[ -w /dev/tty ]]; then
    printf '\033]0;%s\a' "$title" > /dev/tty
  else
    printf '\033]0;%s\a' "$title"
  fi
}

###############################################################################
# Output Helpers
###############################################################################

print_section() {
  local title="$1"
  local color="${2:-cyan}"

  _iterm_mark
  echo_${color} "========================================"
  echo_${color} "  ${title}"
  echo_${color} "========================================"
}

###############################################################################
# Utility Helpers
###############################################################################

command_exists() {
  command -v "$1" &> /dev/null
}

show_setup_message() {
  local show_messages="${SHOW_SETUP_MESSAGES:-$GOODMORNING_SHOW_SETUP_MESSAGES}"
  if [ "$show_messages" = "true" ]; then
    echo "$*"
  fi
}

_check_dependencies() {
  local missing_critical=()

  if ! command_exists git; then
    missing_critical+=("git")
  fi

  if ! command_exists curl; then
    missing_critical+=("curl")
  fi

  if [ ${#missing_critical[@]} -gt 0 ]; then
    echo_error "Missing critical dependencies: ${missing_critical[*]}" >&2
    echo_yellow "Please install missing tools and try again." >&2
    return 1
  fi

  return 0
}

_safe_source() {
  local script_path="$1"

  if [ ! -f "$script_path" ]; then
    echo_warning "Script not found: $script_path" >&2
    return 1
  fi

  if [ ! -r "$script_path" ]; then
    echo_warning "Script not readable: $script_path" >&2
    return 1
  fi

  if [[ "$OSTYPE" == "darwin"* ]]; then
    local perms=$(stat -f "%Lp" "$script_path" 2>/dev/null)
  else
    local perms=$(stat -c "%a" "$script_path" 2>/dev/null)
  fi

  if [[ "$perms" =~ [0-7][0-7][2367] ]]; then
    echo_warning "Security: Script is world-writable, refusing to source: $script_path" >&2
    return 1
  fi

  source "$script_path"
  return $?
}

###############################################################################
# Visual Feedback Helpers
###############################################################################

# Spinner style definitions
# Each style has: name, characters array, and backspace count per character
typeset -gA SPINNER_STYLES_CHARS
typeset -gA SPINNER_STYLES_BACKSPACES

SPINNER_STYLES_CHARS[moon]="🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘"
SPINNER_STYLES_CHARS[braille]="⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"
SPINNER_STYLES_CHARS[line]="| / - \\"
SPINNER_STYLES_CHARS[bounce]="▁ ▃ ▄ ▅ ▆ ▇ █ ▇ ▆ ▅ ▄ ▃"
SPINNER_STYLES_CHARS[clock]="🕐 🕑 🕒 🕓 🕔 🕕 🕖 🕗 🕘 🕙 🕚 🕛"
SPINNER_STYLES_CHARS[arrows]="← ↖ ↑ ↗ → ↘ ↓ ↙"
SPINNER_STYLES_CHARS[growing]="⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷"
SPINNER_STYLES_CHARS[box]="◰ ◳ ◲ ◱"
SPINNER_STYLES_CHARS[ball]="⠁ ⠂ ⠄ ⠂"
SPINNER_STYLES_CHARS[weather]="☀️  🌤️  ⛅ 🌥️  ☁️ "
SPINNER_STYLES_CHARS[dots]="⠋ ⠙ ⠚ ⠞ ⠖ ⠦ ⠴ ⠲ ⠳ ⠓"
SPINNER_STYLES_CHARS[star]="✶ ✸ ✹ ✺ ✹ ✸"

SPINNER_STYLES_BACKSPACES[moon]=2
SPINNER_STYLES_BACKSPACES[braille]=1
SPINNER_STYLES_BACKSPACES[line]=1
SPINNER_STYLES_BACKSPACES[bounce]=1
SPINNER_STYLES_BACKSPACES[clock]=2
SPINNER_STYLES_BACKSPACES[arrows]=1
SPINNER_STYLES_BACKSPACES[growing]=1
SPINNER_STYLES_BACKSPACES[box]=1
SPINNER_STYLES_BACKSPACES[ball]=1
SPINNER_STYLES_BACKSPACES[weather]=4
SPINNER_STYLES_BACKSPACES[dots]=1
SPINNER_STYLES_BACKSPACES[star]=1

# Available style names for random selection
typeset -ga SPINNER_STYLE_NAMES
SPINNER_STYLE_NAMES=(moon braille line bounce clock arrows growing box ball weather dots star)

# Currently selected spinner style (set once per script invocation)
typeset -g SELECTED_SPINNER_STYLE=""
typeset -ga SELECTED_SPINNER_CHARS
typeset -g SELECTED_SPINNER_BACKSPACES=2

_select_random_spinner_style() {
  if [[ -n "$SELECTED_SPINNER_STYLE" ]]; then
    return 0
  fi

  local style_count=${#SPINNER_STYLE_NAMES[@]}
  local random_index=$((RANDOM % style_count))
  SELECTED_SPINNER_STYLE="${SPINNER_STYLE_NAMES[$((random_index + 1))]}"

  local chars_string="${SPINNER_STYLES_CHARS[$SELECTED_SPINNER_STYLE]}"
  SELECTED_SPINNER_CHARS=(${(s: :)chars_string})
  SELECTED_SPINNER_BACKSPACES="${SPINNER_STYLES_BACKSPACES[$SELECTED_SPINNER_STYLE]}"

  export SELECTED_SPINNER_STYLE
}

_select_random_spinner_style

run_with_spinner() {
  local message="$1"
  shift
  local -a command=("$@")

  # Hide cursor during spinner
  printf "\e[?25l"
  echo -n "  $message... "

  local -a spin_chars=("${SELECTED_SPINNER_CHARS[@]}")
  local spin_index=0
  local timeout=${SPINNER_TIMEOUT:-30}

  "${command[@]}" &
  local pid=$!
  local elapsed=0
  local delay=0.1

  while kill -0 "$pid" 2>/dev/null; do
    if (( elapsed >= timeout )); then
      printf "\e[?25h"  # Restore cursor
      echo ""
      echo_warning "Operation timed out after ${timeout}s"
      kill "$pid" 2>/dev/null
      return 1
    fi

    # Use carriage return to overwrite - works with any character width
    printf "\r  %s... %s  " "$message" "${spin_chars[$((spin_index + 1))]}"
    spin_index=$(( (spin_index + 1) % ${#spin_chars[@]} ))
    sleep "$delay"
    elapsed=$((elapsed + delay))
  done

  wait "$pid"
  local exit_code=$?

  # Restore cursor
  printf "\e[?25h"

  if [[ $exit_code -eq 0 ]]; then
    echo_green "✓"
  else
    echo_red "✗"
    return $exit_code
  fi

  return 0
}

# Fetch data with spinner, capturing output to a variable
# Usage: local result=$(fetch_with_spinner "Loading..." command args)
fetch_with_spinner() {
  local message="$1"
  shift
  local -a command=("$@")

  # Determine if we can use animated spinner
  # Only use /dev/tty for animation - stderr fallback causes corruption with tee
  local use_animation=false
  local tty_out=""

  if [[ -c /dev/tty ]] && [[ -t 0 || -t 1 || -t 2 ]]; then
    # Additional check: verify we can actually write to /dev/tty
    if ( printf "" > /dev/tty ) 2>/dev/null; then
      tty_out="/dev/tty"
      use_animation=true
    fi
  fi

  local timeout=${SPINNER_TIMEOUT:-30}
  local temp_file=$(mktemp)

  # Run command and capture output
  "${command[@]}" > "$temp_file" 2>/dev/null &
  local pid=$!
  local iterations=0
  local max_iterations=$((timeout * 10))  # 10 iterations per second (0.1s delay)

  if [[ "$use_animation" == "true" ]]; then
    # Animated spinner mode - write directly to /dev/tty
    # Hide cursor during animation
    printf "\e[?25l" > "$tty_out" 2>/dev/null
    printf "  %s " "$message" > "$tty_out" 2>/dev/null

    local -a spin_chars=("${SELECTED_SPINNER_CHARS[@]}")
    local spin_index=0

    while kill -0 "$pid" 2>/dev/null; do
      if (( iterations >= max_iterations )); then
        printf "\r  %-70s\r" "" > "$tty_out" 2>/dev/null
        printf "\e[?25h" > "$tty_out" 2>/dev/null  # Restore cursor
        kill "$pid" 2>/dev/null
        rm -f "$temp_file"
        return 1
      fi

      # Use carriage return to overwrite - works with any character width
      printf "\r  %s %s  " "$message" "${spin_chars[$((spin_index + 1))]}" > "$tty_out" 2>/dev/null
      spin_index=$(( (spin_index + 1) % ${#spin_chars[@]} ))
      sleep 0.1
      iterations=$((iterations + 1))
    done

    # Brief pause to let user see the final spinner state
    sleep 1

    # Clear the spinner line and restore cursor
    printf "\r  %-70s\r" "" > "$tty_out" 2>/dev/null
    printf "\e[?25h" > "$tty_out" 2>/dev/null
  else
    # Non-animated mode - no terminal available, just wait silently
    while kill -0 "$pid" 2>/dev/null; do
      if (( iterations >= max_iterations )); then
        kill "$pid" 2>/dev/null
        rm -f "$temp_file"
        return 1
      fi
      sleep 0.1
      iterations=$((iterations + 1))
    done
  fi

  wait "$pid"
  local exit_code=$?

  # Output content if we got any, regardless of exit code
  # (curl can return non-zero with valid partial data)
  if [[ -s "$temp_file" ]]; then
    cat "$temp_file"
  fi

  rm -f "$temp_file"
  return $exit_code
}
