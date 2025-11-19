#!/usr/bin/env zsh

###############################################################################
# Daily Content Functions
#
# Fetches and displays various "daily" content features:
# - Country of the Day (REST Countries API)
# - Word of the Day (Merriam-Webster API)
# - Wikipedia Featured Article
# - NASA Astronomy Picture of the Day (APOD)
#
# All features include caching and offline mode support
###############################################################################

###############################################################################
# Helper Functions
###############################################################################

_safe_display() {
  local value="$1"
  local fallback="${2:-N/A}"

  if [ -z "$value" ] || [ "$value" = "null" ]; then
    echo "$fallback"
  else
    echo "$value"
  fi
}

###############################################################################
# Country of the Day
###############################################################################

_get_country_cache_file() {
  echo "${GOODMORNING_CONFIG_DIR}/cache/country_of_day.json"
}

_get_random_country() {
  local cache_file="$(_get_country_cache_file)"

  if _is_cache_valid "$cache_file"; then
    cat "$cache_file"
    return 0
  fi

  # List of country codes for random selection (avoids /all endpoint issues)
  local country_codes=(
    "usa" "canada" "mexico" "brazil" "argentina" "chile" "peru" "colombia"
    "uk" "france" "germany" "spain" "italy" "netherlands" "belgium" "sweden"
    "norway" "denmark" "finland" "poland" "austria" "switzerland" "portugal"
    "japan" "china" "india" "australia" "newzealand" "southkorea" "thailand"
    "vietnam" "indonesia" "malaysia" "singapore" "philippines" "egypt" "morocco"
    "southafrica" "kenya" "nigeria" "ghana" "israel" "turkey" "greece" "ireland"
  )

  # Use day of year for daily rotation
  local day_of_year=$(date +%j | sed 's/^0*//')
  local index=$((day_of_year % ${#country_codes[@]}))
  local country_name="${country_codes[$index]}"

  local country_data=$(curl -s --max-time 10 "https://restcountries.com/v3.1/name/${country_name}?fullText=false" 2>/dev/null)

  if [ -z "$country_data" ]; then
    return 1
  fi

  # Extract first result from array and validate
  local single_country=$(printf '%s' "$country_data" | jq '.[0]' 2>/dev/null)
  local country_name_check=$(printf '%s' "$country_data" | jq -r '.[0].name.common // empty' 2>/dev/null)

  if [ -n "$country_name_check" ]; then
    mkdir -p "$(dirname "$cache_file")"
    print -r -- "$single_country" > "$cache_file"
    print -r -- "$single_country"
    return 0
  fi

  echo "Country API: Invalid response for $country_name" >&2
  return 1
}

show_country_of_day() {
  if [ -n "$GOODMORNING_FORCE_OFFLINE" ]; then
    return 0
  fi

  print_section "Country of the Day" "cyan"

  local country_data=$(_get_random_country)

  if [ -z "$country_data" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch country information')"
    return 0
  fi

  local name=$(printf '%s' "$country_data" | jq -r '.name.common' 2>/dev/null)
  local official_name=$(printf '%s' "$country_data" | jq -r '.name.official' 2>/dev/null)
  local capital=$(printf '%s' "$country_data" | jq -r '.capital[0]? // "N/A"' 2>/dev/null)
  local region=$(printf '%s' "$country_data" | jq -r '.region' 2>/dev/null)
  local subregion=$(printf '%s' "$country_data" | jq -r '.subregion // "N/A"' 2>/dev/null)
  local population=$(printf '%s' "$country_data" | jq -r '.population' 2>/dev/null)
  local area=$(printf '%s' "$country_data" | jq -r '.area' 2>/dev/null)
  local flag=$(printf '%s' "$country_data" | jq -r '.flag' 2>/dev/null)

  local languages=$(printf '%s' "$country_data" | jq -r '.languages // {} | to_entries | .[].value' 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
  local currencies=$(printf '%s' "$country_data" | jq -r '.currencies // {} | to_entries | .[].value.name' 2>/dev/null | tr '\n' ', ' | sed 's/,$//')

  echo ""
  echo_cyan "  $flag  $name"
  echo_gray "  Official: $official_name"
  echo ""
  echo "  🏛️  Capital: $(echo_green "$capital")"
  echo "  🌍 Region: $region ($subregion)"
  echo "  👥 Population: $(printf "%'d" "$population" 2>/dev/null || echo "$population")"
  echo "  📏 Area: $(printf "%'d" "$area" 2>/dev/null || echo "$area") km²"

  if [ -n "$languages" ]; then
    echo "  🗣️  Languages: $languages"
  fi

  if [ -n "$currencies" ]; then
    echo "  💰 Currency: $currencies"
  fi

  echo ""
  echo_green "  💡 Daily rotation - refreshes every 24 hours"
  echo ""
}

###############################################################################
# Word of the Day (Free Dictionary API)
###############################################################################

_get_word_cache_file() {
  echo "${GOODMORNING_CONFIG_DIR}/cache/word_of_day.json"
}

_get_random_word() {
  # Common interesting words to feature
  local words=(
    "ephemeral" "ubiquitous" "serendipity" "eloquent" "resilient"
    "pragmatic" "meticulous" "tenacious" "juxtaposition" "paradigm"
    "quintessential" "esoteric" "cogent" "pernicious" "sagacious"
    "mellifluous" "ineffable" "sanguine" "perspicacious" "laconic"
    "munificent" "pulchritudinous" "defenestrate" "petrichor" "apricity"
    "susurrus" "vellichor" "sonder" "numinous" "halcyon"
  )
  # Use day of year for daily rotation
  local day_of_year=$(date +%j | sed 's/^0*//')
  local index=$((day_of_year % ${#words[@]}))
  echo "${words[$index]}"
}

_fetch_word_of_day() {
  local cache_file="$(_get_word_cache_file)"

  if _is_cache_valid "$cache_file"; then
    cat "$cache_file"
    return 0
  fi

  local word=$(_get_random_word)
  local word_data=$(curl -s "https://api.dictionaryapi.dev/api/v2/entries/en/$word" 2>/dev/null)

  if [ -z "$word_data" ]; then
    return 1
  fi

  # Extract first definition from response
  local fetched_word=$(printf '%s' "$word_data" | jq -r '.[0].word' 2>/dev/null)
  local phonetic=$(printf '%s' "$word_data" | jq -r '.[0].phonetic // .[0].phonetics[0].text // ""' 2>/dev/null)
  local part_of_speech=$(printf '%s' "$word_data" | jq -r '.[0].meanings[0].partOfSpeech' 2>/dev/null)
  local definition=$(printf '%s' "$word_data" | jq -r '.[0].meanings[0].definitions[0].definition' 2>/dev/null)
  local example=$(printf '%s' "$word_data" | jq -r '.[0].meanings[0].definitions[0].example // ""' 2>/dev/null)

  if [ -n "$fetched_word" ] && [ "$fetched_word" != "null" ]; then
    mkdir -p "$(dirname "$cache_file")"
    # Create clean JSON with jq to handle escaping
    jq -n \
      --arg word "$fetched_word" \
      --arg phonetic "$phonetic" \
      --arg pos "$part_of_speech" \
      --arg def "$definition" \
      --arg ex "$example" \
      '{word: $word, phonetic: $phonetic, partOfSpeech: $pos, definition: $def, example: $ex}' > "$cache_file"
    cat "$cache_file"
    return 0
  fi

  return 1
}

show_word_of_day() {
  if [ -n "$GOODMORNING_FORCE_OFFLINE" ]; then
    return 0
  fi

  print_section "Word of the Day" "cyan"

  local word_data=$(_fetch_word_of_day)

  if [ -z "$word_data" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch word of the day')"
    return 0
  fi

  local word=$(printf '%s' "$word_data" | jq -r '.word' 2>/dev/null)
  local phonetic=$(printf '%s' "$word_data" | jq -r '.phonetic' 2>/dev/null)
  local part_of_speech=$(printf '%s' "$word_data" | jq -r '.partOfSpeech' 2>/dev/null)
  local definition=$(printf '%s' "$word_data" | jq -r '.definition' 2>/dev/null)
  local example=$(printf '%s' "$word_data" | jq -r '.example' 2>/dev/null)

  # Validate we have content
  word=$(_safe_display "$word" "")
  definition=$(_safe_display "$definition" "")

  if [ -z "$word" ] || [ -z "$definition" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Word data unavailable')"
    return 0
  fi

  echo ""
  phonetic=$(_safe_display "$phonetic" "")
  if [ -n "$phonetic" ]; then
    echo_cyan "  📖 $(echo_green "$word") $(echo_gray "$phonetic")"
  else
    echo_cyan "  📖 $(echo_green "$word")"
  fi

  part_of_speech=$(_safe_display "$part_of_speech" "")
  if [ -n "$part_of_speech" ]; then
    echo_gray "     $part_of_speech"
  fi
  echo ""
  echo "  $definition" | fold -s -w 70 | sed 's/^/  /'

  example=$(_safe_display "$example" "")
  if [ -n "$example" ]; then
    echo ""
    echo_gray "  Example: \"$example\""
  fi
  echo ""
}

###############################################################################
# Wikipedia Featured Article
###############################################################################

_get_wikipedia_cache_file() {
  echo "${GOODMORNING_CONFIG_DIR}/cache/wikipedia_featured.json"
}

_fetch_wikipedia_featured() {
  local cache_file="$(_get_wikipedia_cache_file)"

  if _is_cache_valid "$cache_file"; then
    cat "$cache_file"
    return 0
  fi

  local today=$(date +"%Y/%m/%d")
  local wiki_url="https://en.wikipedia.org/api/rest_v1/feed/featured/${today}"
  local article_data=$(curl -s -H "Api-User-Agent: GoodmorningScript/1.0 (personal productivity tool)" "$wiki_url" 2>/dev/null)

  if [ -z "$article_data" ]; then
    return 1
  fi

  # Sanitize control characters that break jq parsing (macOS compatible)
  # Use perl for portable handling of control character removal
  local sanitized_data=$(printf '%s' "$article_data" | perl -pe 's/[\x00-\x08\x0b\x0c\x0e-\x1f]//g' 2>/dev/null)

  mkdir -p "$(dirname "$cache_file")"
  print -r -- "$sanitized_data" > "$cache_file"
  print -r -- "$sanitized_data"
  return 0
}

show_wikipedia_featured() {
  if [ -n "$GOODMORNING_FORCE_OFFLINE" ]; then
    return 0
  fi

  print_section "Wikipedia Featured Article" "cyan"

  local article_data=$(_fetch_wikipedia_featured)

  if [ -z "$article_data" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch Wikipedia featured article')"
    return 0
  fi

  local title=$(printf '%s' "$article_data" | jq -r '.tfa.title' 2>/dev/null)
  local extract=$(printf '%s' "$article_data" | jq -r '.tfa.extract' 2>/dev/null)
  local url=$(printf '%s' "$article_data" | jq -r '.tfa.content_urls.desktop.page' 2>/dev/null)

  # Check if we got valid data
  title=$(_safe_display "$title" "")
  extract=$(_safe_display "$extract" "")
  url=$(_safe_display "$url" "")

  if [ -z "$title" ] && [ -z "$extract" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Wikipedia article data unavailable')"
    return 0
  fi

  echo ""
  if [ -n "$title" ]; then
    echo_cyan "  📰 $(echo_green "$title")"
    echo ""
  fi
  if [ -n "$extract" ]; then
    echo "$extract" | fold -s -w 70 | sed 's/^/  /'
    echo ""
  fi
  if [ -n "$url" ]; then
    echo_cyan "  🔗 $url"
    echo ""
  fi
}

###############################################################################
# NASA Astronomy Picture of the Day (APOD)
###############################################################################

_get_apod_cache_file() {
  echo "${GOODMORNING_CONFIG_DIR}/cache/apod.json"
}

_get_apod_image_file() {
  echo "${GOODMORNING_CONFIG_DIR}/cache/apod_image.jpg"
}

_fetch_apod() {
  local cache_file="$(_get_apod_cache_file)"

  if _is_cache_valid "$cache_file"; then
    cat "$cache_file"
    return 0
  fi

  local api_key="${GOODMORNING_NASA_API_KEY:-DEMO_KEY}"
  local apod_url="https://api.nasa.gov/planetary/apod?api_key=${api_key}"
  local apod_data=$(curl -s "$apod_url" 2>/dev/null)

  if [ -z "$apod_data" ]; then
    return 1
  fi

  mkdir -p "$(dirname "$cache_file")"
  print -r -- "$apod_data" > "$cache_file"
  print -r -- "$apod_data"
  return 0
}

_display_image_iterm() {
  local image_file="$1"

  if [ ! -f "$image_file" ]; then
    return 1
  fi

  if [[ "$TERM_PROGRAM" != "iTerm.app" ]]; then
    return 1
  fi

  printf '\033]1337;File=inline=1:'
  base64 < "$image_file"
  printf '\a\n'
}

show_apod() {
  if [ -n "$GOODMORNING_FORCE_OFFLINE" ]; then
    return 0
  fi

  print_section "Astronomy Picture of the Day" "cyan"

  local apod_data=$(_fetch_apod)

  if [ -z "$apod_data" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch APOD')"
    show_setup_message "$(echo_yellow '    Set GOODMORNING_NASA_API_KEY for higher rate limits')"
    return 0
  fi

  local title=$(printf '%s' "$apod_data" | jq -r '.title' 2>/dev/null)
  local explanation=$(printf '%s' "$apod_data" | jq -r '.explanation' 2>/dev/null)
  local url=$(printf '%s' "$apod_data" | jq -r '.url' 2>/dev/null)
  local media_type=$(printf '%s' "$apod_data" | jq -r '.media_type' 2>/dev/null)
  local image_file="$(_get_apod_image_file)"

  echo ""
  echo_cyan "  🌌 $(echo_green "$title")"
  echo ""

  if [ "$media_type" = "image" ] && [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    if [ ! -f "$image_file" ] || ! _is_cache_valid "$image_file"; then
      curl -s "$url" -o "$image_file" 2>/dev/null
    fi

    if [ -f "$image_file" ]; then
      echo "  $(echo_yellow 'Displaying image in iTerm...')"
      echo ""
      _display_image_iterm "$image_file"
      echo ""
    fi
  fi

  echo "$explanation" | fold -s -w 70 | sed 's/^/  /'
  echo ""
  local display_url=$(_safe_display "$url" "No URL available")
  echo_cyan "  🔗 $display_url"
  echo ""
}
