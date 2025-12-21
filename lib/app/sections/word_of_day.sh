#!/usr/bin/env zsh

###############################################################################
# Word of the Day Section
#
# Displays word definitions using Free Dictionary API
###############################################################################

register_section "word_of_day" --tools "curl" "jq" --network

###############################################################################
# fetch_word_of_day - Try words until one has a definition in the API
#
# Uses day-based selection from system dictionary, iterating through candidates
# until finding one that exists in the Free Dictionary API.
###############################################################################
fetch_word_of_day() {
  local dict_file="/usr/share/dict/words"
  local day_of_year=$(date +%j | sed 's/^0*//')
  local max_attempts=10

  # Get candidate words based on day of year
  local candidates=()
  if [[ -f "$dict_file" ]]; then
    # Get multiple candidates by offsetting from the day
    for offset in 0 1 2 3 4 5 6 7 8 9; do
      local idx=$(( (day_of_year + offset) % 50 ))
      local word=$(grep -E '^[a-z]{7,12}$' "$dict_file" | awk "NR % 50 == $idx" | head -1)
      [[ -n "$word" ]] && candidates+=("$word")
    done
  fi

  # Add fallbacks
  candidates+=("ephemeral" "serendipity" "eloquent" "resilient" "catalyst")

  # Try each candidate until one works
  for word in "${candidates[@]}"; do
    local word_data
    local retry

    # Retry up to 2 times per word with increasing timeout
    for retry in 1 2; do
      word_data=$(fetch_url "https://api.dictionaryapi.dev/api/v2/entries/en/$word" $((retry * 5)))
      [[ -n "$word_data" ]] && break
      sleep $((RANDOM % 3 + 1))
    done

    # Check if API returned a valid definition (not an error)
    if [[ -n "$word_data" ]] && ! echo "$word_data" | grep -q '"title":"No Definitions Found"'; then
      local fetched_word=$(jq_extract "$word_data" '.[0].word')
      [[ -z "$fetched_word" ]] && continue

      local phonetic=$(printf '%s' "$word_data" | jq -r '.[0].phonetic // .[0].phonetics[0].text // ""' 2>> "$LOG_FILE")
      local part_of_speech=$(jq_extract "$word_data" '.[0].meanings[0].partOfSpeech')
      local definition=$(jq_extract "$word_data" '.[0].meanings[0].definitions[0].definition')
      local example=$(printf '%s' "$word_data" | jq -r '.[0].meanings[0].definitions[0].example // ""' 2>> "$LOG_FILE")

      jq -n \
        --arg word "$fetched_word" \
        --arg phonetic "$phonetic" \
        --arg pos "$part_of_speech" \
        --arg def "$definition" \
        --arg ex "$example" \
        '{word: $word, phonetic: $phonetic, partOfSpeech: $pos, definition: $def, example: $ex}'
      return 0
    fi
  done

  return 1
}

show_word_of_day() {
  print_section "Word of the Day" "cyan"

  local word_data=$(fetch_with_spinner "Fetching word..." fetch_word_of_day)

  if [ -z "$word_data" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch word of the day')"
    return 0
  fi

  local word=$(jq_extract "$word_data" '.word')
  local phonetic=$(jq_extract "$word_data" '.phonetic')
  local part_of_speech=$(jq_extract "$word_data" '.partOfSpeech')
  local definition=$(jq_extract "$word_data" '.definition')
  local example=$(jq_extract "$word_data" '.example')

  word=$(safe_display "$word" "")
  definition=$(safe_display "$definition" "")

  if [ -z "$word" ] || [ -z "$definition" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Word data unavailable')"
    return 0
  fi

  show_new_line
  phonetic=$(safe_display "$phonetic" "")
  if [ -n "$phonetic" ]; then
    echo_cyan "  📖 $(echo_green "$word") $(echo_gray "$phonetic")"
  else
    echo_cyan "  📖 $(echo_green "$word")"
  fi

  part_of_speech=$(safe_display "$part_of_speech" "")
  if [ -n "$part_of_speech" ]; then
    echo_gray "     $part_of_speech"
  fi
  show_new_line
  echo "  $definition" | fold -s -w 70 | sed 's/^/  /'

  example=$(safe_display "$example" "")
  if [ -n "$example" ] && [ "$example" != "N/A" ]; then
    show_new_line
    echo_gray "  Example: \"$example\""
  fi
  show_new_line
}
