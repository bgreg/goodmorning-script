#!/usr/bin/env zsh

###############################################################################
# Image Display Test Helpers
###############################################################################

create_test_image() {
  local output_file="${1:-/tmp/test_image.png}"
  printf '\x89PNG\r\n\x1a\n' > "$output_file"
  printf '\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01' >> "$output_file"
  printf '\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx' >> "$output_file"
  printf '\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N' >> "$output_file"
  printf '\x00\x00\x00\x00IEND\xaeB\x60\x82' >> "$output_file"
  echo "$output_file"
}

validate_iterm_sequence_structure() {
  local sequence="$1"
  [[ "$sequence" == $'\033]1337;File='* ]] || return 1
  [[ "$sequence" == *'inline=1'* ]] || return 1
  return 0
}

validate_iterm_sequence_terminator() {
  local sequence="$1"
  local last_char="${sequence: -1}"
  [[ "$last_char" == $'\a' ]] || [[ "$last_char" == $'\007' ]]
}

validate_iterm_sequence_no_embedded_newlines() {
  local sequence="$1"
  local payload="${sequence#*:}"
  payload="${payload%$'\a'*}"
  [[ "$payload" != *$'\n'* ]]
}

extract_base64_from_sequence() {
  local sequence="$1"
  local payload="${sequence#*:}"
  payload="${payload%$'\a'*}"
  printf '%s' "$payload"
}

validate_base64_decodes_to_image() {
  local base64_data="$1"
  local temp_file
  temp_file=$(mktemp)
  trap "rm -f '$temp_file'" RETURN

  printf '%s' "$base64_data" | base64 -d > "$temp_file" 2>/dev/null || return 1
  file "$temp_file" | grep -qE 'image|PNG|JPEG|GIF' || return 1
  return 0
}

mock_iterm_environment() {
  export TERM_PROGRAM="iTerm.app"
  export LC_TERMINAL="iTerm2"
  export ITERM_SESSION_ID="test-session"
}

unmock_iterm_environment() {
  unset TERM_PROGRAM
  unset LC_TERMINAL
  unset ITERM_SESSION_ID
}

capture_image_display() {
  local image_file="$1"
  export GOODMORNING_IMAGE_CAPTURE_MODE=1
  local output
  output=$(_display_image_iterm "$image_file")
  local status=$?
  unset GOODMORNING_IMAGE_CAPTURE_MODE
  printf '%s' "$output"
  return $status
}

count_osc_markers() {
  local sequence="$1"
  printf '%s' "$sequence" | grep -o $'\033]1337' | wc -l | tr -d ' '
}

count_bel_terminators() {
  local sequence="$1"
  printf '%s' "$sequence" | grep -o $'\a' | wc -l | tr -d ' '
}

validate_sequence_boundaries() {
  local sequence="$1"
  local first_two=$(printf '%s' "$sequence" | head -c 2 | xxd -p)
  local last_one=$(printf '%s' "$sequence" | tail -c 1 | xxd -p)
  [[ "$first_two" == "1b5d" ]] && [[ "$last_one" == "07" ]]
}

validate_base64_charset() {
  local sequence="$1"
  local payload="${sequence#*:}"
  payload="${payload%$'\a'}"
  [[ "$payload" =~ ^[A-Za-z0-9+/=]+$ ]]
}

validate_size_parameter_matches_file() {
  local sequence="$1"
  local image_file="$2"
  local actual_size=$(wc -c < "$image_file" | tr -d ' ')
  [[ "$sequence" == *"size=${actual_size}"* ]]
}

validate_round_trip_integrity() {
  local sequence="$1"
  local original_file="$2"
  local payload="${sequence#*:}"
  payload="${payload%$'\a'}"
  local temp_decoded=$(mktemp)
  printf '%s' "$payload" | base64 -d > "$temp_decoded" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    rm -f "$temp_decoded"
    return 1
  fi
  local original_md5=$(md5 -q "$original_file" 2>/dev/null || md5sum "$original_file" | cut -d' ' -f1)
  local decoded_md5=$(md5 -q "$temp_decoded" 2>/dev/null || md5sum "$temp_decoded" | cut -d' ' -f1)
  rm -f "$temp_decoded"
  [[ "$original_md5" == "$decoded_md5" ]]
}

validate_single_colon_separator() {
  local sequence="$1"
  local header="${sequence%%:*}"
  local after_first_colon="${sequence#*:}"
  [[ "$header" == *"File="* ]] && [[ "$after_first_colon" != "$sequence" ]]
}
