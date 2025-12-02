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

cleanup_temp_files() {
  local file
  local pid

  # Guard: Only clean up files in /tmp or /private/tmp to prevent accidents
  for file in "${TEMP_FILES[@]}"; do
    # Validate file path before deletion
    if [[ ! "$file" =~ ^/tmp/ ]] && [[ ! "$file" =~ ^/private/tmp/ ]] && [[ ! "$file" =~ ^/var/tmp/ ]]; then
      echo "Warning: Skipping cleanup of file outside temp directory: $file" >> "$LOG_FILE" 2>&1
      continue
    fi

    if [ -f "$file" ]; then
      # Use rm without -f to respect file permissions and get errors
      rm "$file" 2>> "$LOG_FILE" || true
    fi
  done

  for pid in "${BACKGROUND_PIDS[@]}"; do
    if kill -0 "$pid" 2>> "$LOG_FILE"; then
      kill "$pid" 2>> "$LOG_FILE"
    fi
  done
}

# when the script exits or is interrupted, run cleanup
trap cleanup_temp_files EXIT INT TERM

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
    if [[ -w /dev/tty ]]; then
      printf '\033]1337;SetMark\a' > /dev/tty
    else
      printf '\033]1337;SetMark\a'
    fi
  fi
}

iterm_notify() {
  local message="$1"
  if [[ "$TERM_PROGRAM" == "iTerm.app" || "$LC_TERMINAL" == "iTerm2" ]]; then
    if [[ -w /dev/tty ]]; then
      printf '\033]9;%s\a' "$message" > /dev/tty
    else
      printf '\033]9;%s\a' "$message"
    fi
  fi
}

iterm_set_badge() {
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

iterm_set_title() {
  local title="$1"
  if [[ -w /dev/tty ]]; then
    printf '\033]0;%s\a' "$title" > /dev/tty
  else
    printf '\033]0;%s\a' "$title"
  fi
}

iterm_create_status_badge() {
  local mail_count=0
  local reminder_count=0
  local calendar_count=0

  # Count unread mail (silent, non-blocking)
  if osascript "$SCRIPT_DIR/lib/app/apple_script/count_mail.scpt" &>/dev/null; then
    mail_count=$(osascript "$SCRIPT_DIR/lib/app/apple_script/count_mail.scpt" 2>/dev/null || echo "0")
    [[ "$mail_count" =~ ^[0-9]+$ ]] || mail_count=0
  fi

  # Count incomplete reminders (silent, non-blocking)
  if osascript "$SCRIPT_DIR/lib/app/apple_script/count_reminders.scpt" &>/dev/null; then
    reminder_count=$(osascript "$SCRIPT_DIR/lib/app/apple_script/count_reminders.scpt" 2>/dev/null || echo "0")
    [[ "$reminder_count" =~ ^[0-9]+$ ]] || reminder_count=0
  fi

  # Count today's calendar events (silent, non-blocking)
  if osascript "$SCRIPT_DIR/lib/app/apple_script/count_calendar.scpt" &>/dev/null; then
    calendar_count=$(osascript "$SCRIPT_DIR/lib/app/apple_script/count_calendar.scpt" 2>/dev/null || echo "0")
    [[ "$calendar_count" =~ ^[0-9]+$ ]] || calendar_count=0
  fi

  # Create badge with counts (using blue/green theme)
  local badge_text="📧 $mail_count  ✅ $reminder_count  📅 $calendar_count"
  echo "$badge_text"
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
  local random_index=$((RANDOM % style_count))
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

###############################################################################
# iTerm2 Inline Image Display
###############################################################################

iterm_can_display_images() {
  [[ "$TERM_PROGRAM" == "iTerm.app" || "$LC_TERMINAL" == "iTerm2" ]]
}

tty_is_available() {
  [[ -c /dev/tty ]] && [[ -w /dev/tty ]]
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
    printf '%s\n' "$sequence" > /dev/tty
    return 0
  fi

  if [[ -n "$GOODMORNING_TERMINAL_FD" ]] && { true >&${GOODMORNING_TERMINAL_FD}; } 2>/dev/null; then
    printf '%s\n' "$sequence" >&${GOODMORNING_TERMINAL_FD}
    return 0
  fi

  return 1
}
