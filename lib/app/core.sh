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

cleanup_background_processes() {
  local pid

  if [ ${#BACKGROUND_PIDS[@]} -gt 0 ]; then
    for pid in "${BACKGROUND_PIDS[@]}"; do
      [[ -z "$pid" ]] && continue

      if kill -0 "$pid" 2>> "$LOG_FILE"; then
        kill "$pid" 2>> "$LOG_FILE"
      fi
    done
  fi
}

# Register cleanup handler for script termination (EXIT, INT, TERM signals)
trap cleanup_background_processes EXIT INT TERM

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

iterm_mark() {
  if [[ "$TERM_PROGRAM" == "iTerm.app" || "$LC_TERMINAL" == "iTerm2" ]]; then
    ( printf '\033]1337;SetMark\a' > /dev/tty ) 2>/dev/null || true
  fi
}

iterm_notify() {
  local message="$1"
  if [[ "$TERM_PROGRAM" == "iTerm.app" || "$LC_TERMINAL" == "iTerm2" ]]; then
    ( printf '\033]9;%s\a' "$message" > /dev/tty ) 2>/dev/null || true
  fi
}

iterm_set_badge() {
  local badge_text="$1"
  if [[ "$TERM_PROGRAM" == "iTerm.app" || "$LC_TERMINAL" == "iTerm2" ]]; then
    local encoded
    encoded=$(printf '%s' "$badge_text" | base64)
    ( printf '\033]1337;SetBadgeFormat=%s\a' "$encoded" > /dev/tty ) 2>/dev/null || true
  fi
}

iterm_set_title() {
  local title="$1"
  # Try to write to /dev/tty, suppress all errors and fallback output
  ( printf '\033]0;%s\a' "$title" > /dev/tty ) 2>/dev/null || true
}

_fetch_count_with_timeout() {
  local script_path="$1"
  local timeout_seconds="${2:-2}"
  local count=0

  if timeout $timeout_seconds osascript "$script_path" &>/dev/null; then
    count=$(timeout $timeout_seconds osascript "$script_path" 2>/dev/null || echo "0")
    [[ "$count" =~ ^[0-9]+$ ]] || count=0
  fi

  echo "$count"
}

iterm_create_status_badge() {
  local mail_count=$(_fetch_count_with_timeout "$SCRIPT_DIR/lib/app/apple_script/count_mail.scpt")
  local reminder_count=$(_fetch_count_with_timeout "$SCRIPT_DIR/lib/app/apple_script/count_reminders.scpt")
  local calendar_count=$(_fetch_count_with_timeout "$SCRIPT_DIR/lib/app/apple_script/count_calendar.scpt")

  echo "📧 $mail_count  ✅ $reminder_count  📅 $calendar_count"
}

###############################################################################
# Output Helpers
###############################################################################

print_section() {
  local title="$1"
  local color="${2:-cyan}"

  iterm_mark
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

check_dependencies() {
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

safe_source() {
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

select_random_spinner_style() {
  if [[ -n "$SELECTED_SPINNER_STYLE" ]]; then
    return 0
  fi

  local style_count=${#SPINNER_STYLE_NAMES[@]}
  local random_index=$(random_in_range "$style_count")
  SELECTED_SPINNER_STYLE="${SPINNER_STYLE_NAMES[$((random_index + 1))]}"

  local chars_string="${SPINNER_STYLES_CHARS[$SELECTED_SPINNER_STYLE]}"
  SELECTED_SPINNER_CHARS=(${(s: :)chars_string})
  SELECTED_SPINNER_BACKSPACES="${SPINNER_STYLES_BACKSPACES[$SELECTED_SPINNER_STYLE]}"

  export SELECTED_SPINNER_STYLE
}

select_random_spinner_style

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
      show_new_line
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

  printf "\e[?25h"

  if [[ $exit_code -eq 0 ]]; then
    echo_green "✓"
  else
    echo_red "✗"
    return $exit_code
  fi

  return 0
}

###############################################################################
# Spinner Helper Functions
###############################################################################

# Constants for spinner timing
readonly SPINNER_ITERATIONS_PER_SECOND=10
readonly SPINNER_SLEEP_INTERVAL=0.1
readonly SPINNER_CLEAR_WIDTH=70

_hide_cursor() {
  local tty_out="$1"
  printf "\e[?25l" > "$tty_out" 2>/dev/null
}

_show_cursor() {
  local tty_out="$1"
  printf "\e[?25h" > "$tty_out" 2>/dev/null
}

_clear_spinner_line() {
  local tty_out="$1"
  printf "\r  %-${SPINNER_CLEAR_WIDTH}s\r" "" > "$tty_out" 2>/dev/null
}

# Check if process has exceeded timeout
# Returns: 0 if timeout exceeded, 1 if still within timeout
_has_timed_out() {
  local iterations="$1"
  local max_iterations="$2"
  (( iterations >= max_iterations ))
}

# Handle timeout: cleanup and return error
_handle_timeout() {
  local pid="$1"
  local tty_out="$2"
  _clear_spinner_line "$tty_out"
  _show_cursor "$tty_out"
  kill "$pid" 2>/dev/null
  exec 3<&-
  return 1
}

# Run animated spinner while process executes
_run_animated_spinner() {
  local message="$1"
  local pid="$2"
  local tty_out="$3"
  local max_iterations="$4"

  _hide_cursor "$tty_out"
  printf "  %s " "$message" > "$tty_out" 2>/dev/null

  local -a spin_chars=("${SELECTED_SPINNER_CHARS[@]}")
  local spin_index=0
  local iterations=0

  while kill -0 "$pid" 2>/dev/null; do
    if _has_timed_out "$iterations" "$max_iterations"; then
      _handle_timeout "$pid" "$tty_out"
      return 1
    fi

    printf "\r  %s %s  " "$message" "${spin_chars[$((spin_index + 1))]}" > "$tty_out" 2>/dev/null
    spin_index=$(( (spin_index + 1) % ${#spin_chars[@]} ))
    sleep "$SPINNER_SLEEP_INTERVAL"
    iterations=$((iterations + 1))
  done

  sleep 1
  _clear_spinner_line "$tty_out"
  _show_cursor "$tty_out"
  return 0
}

# Wait silently for process to complete (no animation)
_wait_silently() {
  local pid="$1"
  local max_iterations="$2"
  local iterations=0

  while kill -0 "$pid" 2>/dev/null; do
    if _has_timed_out "$iterations" "$max_iterations"; then
      kill "$pid" 2>/dev/null
      exec 3<&-
      return 1
    fi
    sleep "$SPINNER_SLEEP_INTERVAL"
    iterations=$((iterations + 1))
  done

  return 0
}

# Fetch data with spinner, capturing output to a variable
# Usage: local result=$(fetch_with_spinner "Loading..." command args)
fetch_with_spinner() {
  local message="$1"
  shift
  local -a command=("$@")
  local use_animation=false
  local tty_out=""

  if [[ -c /dev/tty ]] 2>/dev/null && [[ -t 0 || -t 1 || -t 2 ]] 2>/dev/null; then
    if ( printf "" > /dev/tty ) 2>/dev/null; then
      tty_out="/dev/tty"
      use_animation=true
    fi
  fi

  local timeout=${SPINNER_TIMEOUT:-30}
  local max_iterations=$((timeout * SPINNER_ITERATIONS_PER_SECOND))
  local output=""

  exec 3< <("${command[@]}" 2>/dev/null)
  local pid=$!

  if [[ "$use_animation" == "true" ]]; then
    _run_animated_spinner "$message" "$pid" "$tty_out" "$max_iterations" || return 1
  else
    _wait_silently "$pid" "$max_iterations" || return 1
  fi

  wait "$pid"
  local exit_code=$?

  output=$(cat <&3)
  exec 3<&-

  if [[ -n "$output" ]]; then
    printf '%s\n' "$output"
  fi

  return $exit_code
}

###############################################################################
# iTerm2 Inline Image Display
###############################################################################

iterm_can_display_images() {
  [[ "$TERM_PROGRAM" == "iTerm.app" || "$LC_TERMINAL" == "iTerm2" ]]
}

tty_is_available() {
  [[ -c /dev/tty ]] 2>/dev/null && [[ -w /dev/tty ]] 2>/dev/null
}

generate_iterm_image_sequence() {
  local image_file="$1"
  local max_width="${2:-${GOODMORNING_IMAGE_WIDTH:-60}}"

  [[ -f "$image_file" ]] || return 1

  local file_size=$(wc -c < "$image_file" 2>/dev/null | tr -d ' ')
  local encoded=$(base64 < "$image_file" | tr -d '\n')

  printf '\033]1337;File=inline=1;size=%s;width=%s;preserveAspectRatio=1:%s\a' \
    "$file_size" "$max_width" "$encoded"
}

validate_image_file() {
  local image_file="$1"

  [[ -f "$image_file" ]] || return 1
  [[ -s "$image_file" ]] || return 1

  local file_type
  file_type=$(file -b "$image_file" 2>/dev/null)

  case "$file_type" in
    *PNG*|*JPEG*|*GIF*|*image*|*bitmap*|*JFIF*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

download_image() {
  local url="$1"
  local output_file="$2"
  local max_retries="${3:-2}"
  local attempt=1

  while [[ $attempt -le $max_retries ]]; do
    curl -sL --max-time 15 "$url" -o "$output_file" 2>/dev/null

    if validate_image_file "$output_file"; then
      return 0
    fi

    rm -f "$output_file"
    ((attempt++))
    sleep 1
  done

  return 1
}

display_image_iterm() {
  local image_file="$1"

  [[ -f "$image_file" ]] || return 1
  iterm_can_display_images || return 1

  local sequence
  sequence=$(generate_iterm_image_sequence "$image_file") || return 1

  if [[ -n "$GOODMORNING_IMAGE_CAPTURE_MODE" ]]; then
    printf '%s\n' "$sequence"
    return 0
  fi

  if tty_is_available; then
    ( printf '%s\n' "$sequence" > /dev/tty ) 2>/dev/null && return 0
  fi

  if [[ -n "$GOODMORNING_TERMINAL_FD" ]] && { true >&${GOODMORNING_TERMINAL_FD}; } 2>/dev/null; then
    printf '%s\n' "$sequence" >&${GOODMORNING_TERMINAL_FD}
    return 0
  fi

  return 1
}
