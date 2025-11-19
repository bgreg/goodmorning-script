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
# Output Helpers
###############################################################################

print_section() {
  local title="$1"
  local color="${2:-cyan}"

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

run_with_spinner() {
  local message="$1"
  shift
  local -a command=("$@")

  echo -n "  $message... "

  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local timeout=${SPINNER_TIMEOUT:-30}

  "${command[@]}" &
  local pid=$!
  local elapsed=0
  local delay=0.1

  while kill -0 "$pid" 2>/dev/null; do
    if (( elapsed >= timeout )); then
      echo ""
      echo_warning "Operation timed out after ${timeout}s"
      kill "$pid" 2>/dev/null
      return 1
    fi

    local temp=${spinstr#?}
    printf "[%c]" "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep "$delay"
    printf "\b\b\b"
    elapsed=$((elapsed + delay))
  done

  wait "$pid"
  local exit_code=$?

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

  # Write spinner directly to terminal to avoid tee interference
  # Try /dev/tty first, fall back to stderr if unavailable
  local tty_out="/dev/stderr"
  if [[ -c /dev/tty ]] && ( echo -n "" > /dev/tty ) 2>/dev/null; then
    tty_out="/dev/tty"
  fi

  echo -n "  $message " > "$tty_out" 2>/dev/null

  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local timeout=${SPINNER_TIMEOUT:-30}
  local temp_file=$(mktemp)

  # Run command and capture output
  "${command[@]}" > "$temp_file" 2>/dev/null &
  local pid=$!
  local iterations=0
  local max_iterations=$((timeout * 10))  # 10 iterations per second (0.1s delay)

  while kill -0 "$pid" 2>/dev/null; do
    if (( iterations >= max_iterations )); then
      printf "\r  %-60s\r" "" > "$tty_out" 2>/dev/null
      kill "$pid" 2>/dev/null
      rm -f "$temp_file"
      return 1
    fi

    local temp=${spinstr#?}
    printf "[%c]" "$spinstr" > "$tty_out" 2>/dev/null
    spinstr=$temp${spinstr%"$temp"}
    sleep 0.1
    printf "\b\b\b" > "$tty_out" 2>/dev/null
    iterations=$((iterations + 1))
  done

  wait "$pid"
  local exit_code=$?

  # Clear the spinner line
  printf "\r  %-60s\r" "" > "$tty_out" 2>/dev/null

  if [[ $exit_code -eq 0 ]]; then
    cat "$temp_file"
  fi

  rm -f "$temp_file"
  return $exit_code
}
