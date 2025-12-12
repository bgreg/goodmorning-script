# Global utility functions available to all scripts
# Source this early - before other lib files

# Output a blank line for visual spacing
show_new_line() {
  echo ""
}

# Helper function to source library files with optional required validation
# Usage: _source_lib "lib/app/colors.sh" [required]
# Returns: 0 if file sourced successfully, 1 if file missing
_source_lib() {
  local file="$SCRIPT_DIR/$1"
  local required="${2:-}"

  if [ -f "$file" ]; then
    source "$file"
    return 0
  else
    if [[ "$required" == "required" ]]; then
      echo "Error: Required file missing: $1" >&2
      return 1
    fi
    return 1
  fi
}

# Start a fire-and-forget background process with proper cleanup tracking
# Usage: _start_background_process function_name
# The function is called in background with output suppressed
# PID is tracked in BACKGROUND_PIDS for cleanup on script exit
_start_background_process() {
  local command_func="$1"
  setopt LOCAL_OPTIONS NO_NOTIFY NO_MONITOR
  "$command_func" >/dev/null 2>&1 &
  local pid=$!
  BACKGROUND_PIDS+=($pid)
  disown %% 2>> "$LOG_FILE"
  return 0
}

# Extract a field from JSON data using jq
# Usage: jq_extract "$json_data" '.path.to.field'
# Returns empty string if field is null/missing
jq_extract() {
  local json="$1"
  local jq_path="$2"
  printf '%s' "$json" | jq -r "${jq_path} // empty" 2>/dev/null
}

###############################################################################
# HTTP Fetch Utilities
###############################################################################

# Fetch URL with standard timeout and options
# Usage: fetch_url "https://example.com" [timeout_seconds]
# Returns: URL content on success, empty on failure
fetch_url() {
  local url="$1"
  local timeout="${2:-10}"
  curl -s --max-time "$timeout" "$url" 2>/dev/null
}

# Fetch URL with compression support (for sitemaps, large content)
# Usage: fetch_url_compressed "https://example.com/sitemap.xml" [timeout_seconds]
# Returns: URL content on success, empty on failure
fetch_url_compressed() {
  local url="$1"
  local timeout="${2:-10}"
  curl -s -L --compressed --max-time "$timeout" "$url" 2>/dev/null
}

###############################################################################
# Random Selection Utilities
###############################################################################

# Generate random number within range [0, max)
# Usage: random_in_range $max_value
# Returns: Random number from 0 to max_value-1
random_in_range() {
  local max="$1"
  echo $((RANDOM % max))
}

# Select random element from array
# Usage: random_array_element "${array[@]}"
# Returns: Random element from array, or empty if array is empty
random_array_element() {
  local -a arr=("$@")
  local count=${#arr[@]}

  if [[ $count -eq 0 ]]; then
    return 1
  fi

  local index=$((RANDOM % count + 1))
  echo "${arr[$index]}"
}

###############################################################################
# String Transformation Utilities
###############################################################################

# Convert string to title case (First Letter Of Each Word Capitalized)
# Usage: to_title_case "hello world"
# Returns: "Hello World"
to_title_case() {
  local text="$1"
  echo "$text" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1'
}

###############################################################################
# Validation Utilities
###############################################################################

# Check if variable is empty and return early if so
# Usage: require_non_empty "$variable" || return 1
# Returns: 0 if non-empty, 1 if empty
require_non_empty() {
  local value="$1"
  [[ -n "$value" ]]
}

###############################################################################
# Display Utilities
###############################################################################

# Display warning message with safe_display
# Usage: show_warning_message "message text"
show_warning_message() {
  local message="$1"
  show_setup_message "$(echo_yellow "  ⚠ $message")"
}
