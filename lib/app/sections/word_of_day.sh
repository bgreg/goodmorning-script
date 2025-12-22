#!/usr/bin/env zsh

###############################################################################
# Word of the Day Section
#
# Displays word definitions using macOS built-in dictionary (fully offline)
###############################################################################

register_section "word_of_day" --tools "swift"

###############################################################################
# fetch_word_of_day - Get word and definition from macOS dictionary (offline)
#
# Uses Swift to access macOS CoreServices dictionary. Selects an interesting
# word from /usr/share/dict/words based on day of year.
###############################################################################
fetch_word_of_day() {
  local dict_file="/usr/share/dict/words"
  local day_of_year=$(date +%j | sed 's/^0*//')

  # Select a word: filter for interesting words (7-12 chars, lowercase only)
  # Use day of year to pick consistently for the day
  local word

  # Count matching words to ensure selection index is within bounds
  local total_words selected_index
  total_words=$(grep -E '^[a-z]{7,12}$' "$dict_file" 2>/dev/null | wc -l | tr -d ' ')

  if [[ -n "$total_words" && "$total_words" -gt 0 ]]; then
    # Compute a stable index in the range [1, total_words]
    selected_index=$(( (day_of_year * 7) % total_words + 1 ))
    word=$(grep -E '^[a-z]{7,12}$' "$dict_file" 2>/dev/null | awk "NR == $selected_index" | head -1)
  fi

  # Fallback word if dict file fails or selection produced no word
  [[ -z "$word" ]] && word="ephemeral"

  # Use Swift to get definition from macOS dictionary
  local definition
  definition=$(swift -e '
import Foundation
import CoreServices
let args = CommandLine.arguments
guard args.count > 1 else { exit(1) }
let word = args[1]
if let def = DCSCopyTextDefinition(nil, word as CFString, CFRangeMake(0, word.count))?.takeRetainedValue() as String? {
    print(def)
}
' -- "$word" 2>> "$LOG_FILE")

  # If no definition found, try fallback words
  if [[ -z "$definition" ]]; then
    for fallback in "ephemeral" "serendipity" "eloquent" "resilient" "catalyst"; do
      definition=$(swift -e '
import Foundation
import CoreServices
let args = CommandLine.arguments
guard args.count > 1 else { exit(1) }
let word = args[1]
if let def = DCSCopyTextDefinition(nil, word as CFString, CFRangeMake(0, word.count))?.takeRetainedValue() as String? {
    print(def)
}
' -- "$fallback" 2>> "$LOG_FILE")
      [[ -n "$definition" ]] && word="$fallback" && break
    done
  fi

  [[ -z "$definition" ]] && return 1

  # Parse macOS dictionary format: "word syllables | phonetic | part of speech definition..."
  local phonetic part_of_speech def_text

  # Extract phonetic (between | symbols)
  phonetic=$(echo "$definition" | grep -o '| [^|]* |' | head -1 | sed 's/|//g' | xargs)

  # Extract part of speech (first occurrence)
  part_of_speech=$(echo "$definition" | grep -oE '\b(noun|verb|adjective|adverb)\b' | head -1)

  # Extract just the definition text
  # Remove everything up to and including the part of speech, stop at DERIVATIVES/ORIGIN
  def_text=$(echo "$definition" | sed -E "s/^.*$part_of_speech //" | sed -E 's/(DERIVATIVES|ORIGIN|PHRASES|•).*$//' | head -c 250 | xargs)

  # Output as simple tab-separated values
  printf '%s\t%s\t%s\t%s\n' "$word" "$phonetic" "$part_of_speech" "$def_text"
}

show_word_of_day() {
  print_section "Word of the Day" "cyan"

  local word_data
  word_data=$(fetch_with_spinner "Looking up word..." fetch_word_of_day)

  if [[ -z "$word_data" ]]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not find word definition in dictionary')"
    return 0
  fi

  # Parse tab-separated values: word, phonetic, part_of_speech, definition
  local word phonetic part_of_speech definition
  word=$(echo "$word_data" | cut -f1)
  phonetic=$(echo "$word_data" | cut -f2)
  part_of_speech=$(echo "$word_data" | cut -f3)
  definition=$(echo "$word_data" | cut -f4-)

  if [[ -z "$word" ]] || [[ -z "$definition" ]]; then
    show_setup_message "$(echo_yellow '  ⚠ Word data unavailable')"
    return 0
  fi

  show_new_line
  if [[ -n "$phonetic" ]]; then
    echo_cyan "  📖 $(echo_green "$word") $(echo_gray "$phonetic")"
  else
    echo_cyan "  📖 $(echo_green "$word")"
  fi

  if [[ -n "$part_of_speech" ]]; then
    echo_gray "     $part_of_speech"
  fi
  show_new_line
  echo "$definition" | fold -s -w 70 | sed 's/^/  /'
  show_new_line
}
