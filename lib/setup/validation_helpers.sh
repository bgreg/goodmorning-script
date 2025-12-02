#!/usr/bin/env zsh

###############################################################################
# Validation Functions Library
#
# Reusable validation functions for doctor mode and setup validation.
# Can be sourced by setup.sh or other scripts needing validation capabilities.
###############################################################################

# Ensure colors are available
if [[ -z "$COLOR_RESET" ]]; then
  SCRIPT_DIR="${0:a:h:h}"
  source "$SCRIPT_DIR/colors.sh" 2>/dev/null || true
fi

# Source view helpers
if [ -f "$SCRIPT_DIR/view_helpers.sh" ]; then
  source "$SCRIPT_DIR/view_helpers.sh"
fi

# Validation counters (global for summary)
typeset -g VALIDATION_PASSED=0
typeset -g VALIDATION_FAILED=0
typeset -g VALIDATION_WARNED=0

validation_reset_counters() {
  VALIDATION_PASSED=0
  VALIDATION_FAILED=0
  VALIDATION_WARNED=0
}

validation_pass() {
  local check_description="$1"
  local truncated_description
  truncated_description=$(truncate_string "$check_description")

  printf "  %-50s " "$truncated_description"
  echo "💚"
  (( VALIDATION_PASSED++ )) || true
}

validation_fail() {
  local check_description="$1"
  local failure_detail="${2:-}"
  local truncated_description
  truncated_description=$(truncate_string "$check_description")

  printf "  %-50s " "$truncated_description"
  echo -n "💔"
  if [[ -n "$failure_detail" ]]; then
    echo "       $failure_detail"
  else
    echo ""
  fi
  (( VALIDATION_FAILED++ )) || true
}

validation_warn() {
  local check_description="$1"
  local warning_detail="${2:-}"
  local truncated_description
  truncated_description=$(truncate_string "$check_description")

  printf "  %-50s " "$truncated_description"
  echo_yellow -n "⚠"
  if [[ -n "$warning_detail" ]]; then
    echo "       $warning_detail"
  else
    echo ""
  fi
  (( VALIDATION_WARNED++ )) || true
}

validation_info() {
  local info_message="$1"
  echo_cyan "  ℹ $info_message"
}

validation_section() {
  local title="$1"
  echo ""
  echo_blue "  $title"
  echo ""
  printf "  %-50s %-8s %s\n" "Check" "Status" "Notes"
  echo_gray "  ────────────────────────────────────────────────── ──────── ─────────────────────────"
}

###############################################################################
# validate_url - Check if a URL is reachable
#
# Returns 0 if URL returns HTTP 200-299, 1 otherwise
# Usage: validate_url "https://example.com"
###############################################################################
validate_url() {
  local url="$1"
  local timeout="${2:-10}"
  local verbose="${3:-false}"

  if [[ -z "$url" ]]; then
    [[ "$verbose" == "true" ]] && validation_fail "Empty URL provided"
    return 1
  fi

  # Handle special URL schemes
  if [[ "$url" == xkcd:* ]]; then
    [[ "$verbose" == "true" ]] && validation_pass "Special scheme: $url"
    return 0
  fi

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    --connect-timeout "$timeout" \
    --max-time "$((timeout * 2))" \
    -L "$url" 2>/dev/null)

  if [[ "$http_code" =~ ^2[0-9][0-9]$ ]] || [[ "$http_code" == "301" ]] || [[ "$http_code" == "302" ]]; then
    return 0
  else
    return 1
  fi
}

###############################################################################
# validate_sitemap - Check if a sitemap URL returns valid XML with <loc> tags
#
# Returns 0 if sitemap is valid, 1 otherwise
# Usage: validate_sitemap "https://example.com/sitemap.xml"
###############################################################################
validate_sitemap() {
  local url="$1"
  local timeout="${2:-15}"
  local verbose="${3:-false}"

  if [[ -z "$url" ]]; then
    [[ "$verbose" == "true" ]] && validation_fail "Empty sitemap URL"
    return 1
  fi

  local content
  local http_code

  # Fetch sitemap with HTTP code
  local response
  response=$(curl -s -w "\n%{http_code}" \
    --connect-timeout "$timeout" \
    --max-time "$((timeout * 2))" \
    -L "$url" 2>/dev/null)

  http_code=$(echo "$response" | tail -n1)
  content=$(echo "$response" | sed '$d')

  # Check HTTP status
  if [[ ! "$http_code" =~ ^2[0-9][0-9]$ ]]; then
    return 1
  fi

  # Handle gzipped sitemaps
  if [[ "$url" == *.gz ]]; then
    content=$(echo "$content" | gunzip 2>/dev/null)
    if [[ $? -ne 0 ]]; then
      return 1
    fi
  fi

  # Check for XML sitemap indicators (LC_ALL=C handles non-UTF8 content)
  if echo "$content" | LC_ALL=C grep -q '<loc>' 2>/dev/null; then
    return 0
  elif echo "$content" | LC_ALL=C grep -q '<sitemap>' 2>/dev/null; then
    return 0
  elif echo "$content" | LC_ALL=C grep -q '<urlset' 2>/dev/null; then
    return 0
  elif echo "$content" | LC_ALL=C grep -q '<sitemapindex' 2>/dev/null; then
    return 0
  else
    return 1
  fi
}

###############################################################################
# validate_api_key - Test if an API key is valid by making a test request
#
# Returns 0 if API key works, 1 otherwise
# Usage: validate_api_key "weather" "$WEATHER_API_KEY"
###############################################################################
validate_api_key() {
  local api_type="$1"
  local key_value="$2"
  local timeout="${3:-10}"

  if [[ -z "$key_value" ]]; then
    return 1
  fi

  case "$api_type" in
    weather|openweathermap)
      local test_url="https://api.openweathermap.org/data/2.5/weather?q=London&appid=$key_value"
      local response
      response=$(curl -s --connect-timeout "$timeout" "$test_url" 2>/dev/null)
      if echo "$response" | grep -q '"cod":200' 2>/dev/null; then
        return 0
      elif echo "$response" | grep -q '"cod":"200"' 2>/dev/null; then
        return 0
      fi
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

###############################################################################
# validate_script_permissions - Check if a script has executable permissions
#
# Returns 0 if executable, 1 otherwise
# Usage: validate_script_permissions "/path/to/script.sh"
###############################################################################
validate_script_permissions() {
  local script_path="$1"
  local verbose="${2:-false}"

  if [[ ! -f "$script_path" ]]; then
    [[ "$verbose" == "true" ]] && validation_fail "File not found: $script_path"
    return 1
  fi

  if [[ -x "$script_path" ]]; then
    return 0
  else
    return 1
  fi
}

###############################################################################
# validate_json_file - Check if a JSON file is syntactically valid
#
# Returns 0 if valid JSON, 1 otherwise
# Usage: validate_json_file "/path/to/file.json"
###############################################################################
validate_json_file() {
  local json_path="$1"
  local verbose="${2:-false}"

  if [[ ! -f "$json_path" ]]; then
    [[ "$verbose" == "true" ]] && validation_fail "File not found: $json_path"
    return 1
  fi

  if ! command -v jq &>/dev/null; then
    [[ "$verbose" == "true" ]] && validation_warn "jq not installed, cannot validate JSON"
    return 2
  fi

  if jq empty "$json_path" 2>/dev/null; then
    return 0
  else
    return 1
  fi
}

###############################################################################
# validate_dependency - Check if a command/tool is installed
#
# Returns 0 if installed, 1 otherwise
# Usage: validate_dependency "curl"
###############################################################################
validate_dependency() {
  local cmd="$1"

  if command -v "$cmd" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

###############################################################################
# validate_dependencies - Check multiple dependencies at once
#
# Usage: validate_dependencies "curl" "jq" "git"
###############################################################################
validate_dependencies() {
  local missing=()

  for dep in "$@"; do
    if ! validate_dependency "$dep"; then
      missing+=("$dep")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    return 0
  else
    echo "${missing[@]}"
    return 1
  fi
}

###############################################################################
# validate_file_exists - Check if a file exists
#
# Returns 0 if exists, 1 otherwise
# Usage: validate_file_exists "/path/to/file"
###############################################################################
validate_file_exists() {
  local file_path="$1"

  if [[ -f "$file_path" ]]; then
    return 0
  else
    return 1
  fi
}

###############################################################################
# validate_directory_exists - Check if a directory exists
#
# Returns 0 if exists, 1 otherwise
# Usage: validate_directory_exists "/path/to/dir"
###############################################################################
validate_directory_exists() {
  local dir_path="$1"

  if [[ -d "$dir_path" ]]; then
    return 0
  else
    return 1
  fi
}

###############################################################################
# validate_directory_writable - Check if a directory is writable
#
# Returns 0 if writable, 1 otherwise
# Usage: validate_directory_writable "/path/to/dir"
###############################################################################
validate_directory_writable() {
  local dir_path="$1"

  if [[ -d "$dir_path" ]] && [[ -w "$dir_path" ]]; then
    return 0
  else
    return 1
  fi
}
