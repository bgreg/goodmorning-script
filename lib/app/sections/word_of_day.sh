#!/usr/bin/env zsh

###############################################################################
# Word of the Day Section
#
# Displays word definitions using Free Dictionary API
###############################################################################

###############################################################################
# get_deterministic_daily_word - Select interesting word based on day of year
#
# Uses /usr/share/dict/words with filtering criteria:
# - Length: 7-15 characters (interesting but not obscure)
# - Lowercase only (excludes proper nouns)
# - Day-based selection for consistency throughout the day
#
# Returns: A single word, or fallback if dictionary unavailable
###############################################################################
get_deterministic_daily_word() {
  local dict_file="/usr/share/dict/words"

  if [[ ! -f "$dict_file" ]]; then
    echo "ephemeral"
    return
  fi

  local day_of_year=$(date +%j | sed 's/^0*//')

  local word=$(grep -E '^[a-z]{7,15}$' "$dict_file" | \
    sed -n "${day_of_year}~50p" | \
    head -1)

  if [[ -z "$word" ]]; then
    word="serendipity"
  fi

  echo "$word"
}

fetch_word_of_day() {
  local word=$(get_deterministic_daily_word)
  local word_data=$(fetch_url "https://api.dictionaryapi.dev/api/v2/entries/en/$word")

  require_non_empty "$word_data" || return 1

  local fetched_word=$(jq_extract "$word_data" '.[0].word')
  local phonetic=$(printf '%s' "$word_data" | jq -r '.[0].phonetic // .[0].phonetics[0].text // ""' 2>/dev/null)
  local part_of_speech=$(jq_extract "$word_data" '.[0].meanings[0].partOfSpeech')
  local definition=$(jq_extract "$word_data" '.[0].meanings[0].definitions[0].definition')
  local example=$(printf '%s' "$word_data" | jq -r '.[0].meanings[0].definitions[0].example // ""' 2>/dev/null)

  if [[ -n "$fetched_word" ]]; then
    jq -n \
      --arg word "$fetched_word" \
      --arg phonetic "$phonetic" \
      --arg pos "$part_of_speech" \
      --arg def "$definition" \
      --arg ex "$example" \
      '{word: $word, phonetic: $phonetic, partOfSpeech: $pos, definition: $def, example: $ex}'
    return 0
  fi

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
