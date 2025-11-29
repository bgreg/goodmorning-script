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

  local country_data=$(fetch_with_spinner "Fetching country..." _get_random_country)

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

  local word_data=$(fetch_with_spinner "Fetching word..." _fetch_word_of_day)

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
  if [ -n "$example" ] && [ "$example" != "N/A" ]; then
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

  local article_data=$(fetch_with_spinner "Fetching article..." _fetch_wikipedia_featured)

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

  local has_error=$(printf '%s' "$apod_data" | jq -r '.error // empty' 2>/dev/null)
  if [ -n "$has_error" ]; then
    return 1
  fi

  local title=$(printf '%s' "$apod_data" | jq -r '.title // empty' 2>/dev/null)
  if [ -z "$title" ]; then
    return 1
  fi

  mkdir -p "$(dirname "$cache_file")"
  print -r -- "$apod_data" > "$cache_file"
  print -r -- "$apod_data"
  return 0
}

###############################################################################
# iTerm2 Inline Image Display
###############################################################################

_iterm_can_display_images() {
  [[ "$TERM_PROGRAM" == "iTerm.app" || "$LC_TERMINAL" == "iTerm2" ]]
}

_tty_is_available() {
  [[ -c /dev/tty ]] && [[ -w /dev/tty ]]
}

_generate_iterm_image_sequence() {
  local image_file="$1"
  local max_width="${2:-${GOODMORNING_IMAGE_WIDTH:-60}}"

  [[ -f "$image_file" ]] || return 1

  local file_size=$(wc -c < "$image_file" 2>/dev/null | tr -d ' ')
  local encoded=$(base64 < "$image_file" | tr -d '\n')

  printf '\033]1337;File=inline=1;size=%s;width=%s;preserveAspectRatio=1:%s\a' \
    "$file_size" "$max_width" "$encoded"
}

_validate_image_file() {
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

_download_image() {
  local url="$1"
  local output_file="$2"
  local max_retries="${3:-2}"
  local attempt=1

  while [[ $attempt -le $max_retries ]]; do
    curl -sL --max-time 15 "$url" -o "$output_file" 2>/dev/null

    if _validate_image_file "$output_file"; then
      return 0
    fi

    rm -f "$output_file"
    ((attempt++))
    sleep 1
  done

  return 1
}

_display_image_iterm() {
  local image_file="$1"

  [[ -f "$image_file" ]] || return 1
  _iterm_can_display_images || return 1

  local sequence
  sequence=$(_generate_iterm_image_sequence "$image_file") || return 1

  if [[ -n "$GOODMORNING_IMAGE_CAPTURE_MODE" ]]; then
    printf '%s\n' "$sequence"
    return 0
  fi

  if _tty_is_available; then
    printf '%s\n' "$sequence" > /dev/tty
    return 0
  fi

  if [[ -n "$GOODMORNING_TERMINAL_FD" ]] && { true >&${GOODMORNING_TERMINAL_FD}; } 2>/dev/null; then
    printf '%s\n' "$sequence" >&${GOODMORNING_TERMINAL_FD}
    return 0
  fi

  return 1
}

show_apod() {
  if [ -n "$GOODMORNING_FORCE_OFFLINE" ]; then
    return 0
  fi

  print_section "Astronomy Picture of the Day" "cyan"

  local apod_data=$(fetch_with_spinner "Fetching APOD..." _fetch_apod)

  if [ -z "$apod_data" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch APOD')"
    show_setup_message "$(echo_yellow '    Set GOODMORNING_NASA_API_KEY for higher rate limits')"
    return 0
  fi

  local title=$(printf '%s' "$apod_data" | jq -r '.title' 2>/dev/null)
  local explanation=$(printf '%s' "$apod_data" | jq -r '.explanation' 2>/dev/null)
  local url=$(printf '%s' "$apod_data" | jq -r '.url' 2>/dev/null)
  local apod_date=$(printf '%s' "$apod_data" | jq -r '.date' 2>/dev/null)
  local media_type=$(printf '%s' "$apod_data" | jq -r '.media_type' 2>/dev/null)
  local image_file="$(_get_apod_image_file)"

  echo ""
  echo_cyan "  🌌 $(echo_green "$title")"
  echo ""

  if [ "$media_type" = "image" ]; then
    if [ ! -f "$image_file" ] || ! _is_cache_valid "$image_file"; then
      _download_image "$url" "$image_file"
    fi

    if _iterm_can_display_images && _validate_image_file "$image_file"; then
      echo "  $(echo_yellow 'Displaying image in iTerm...')"
      echo ""
      _display_image_iterm "$image_file"
      echo ""
    fi
  fi

  echo "$explanation" | fold -s -w 70 | sed 's/^/  /'
  echo ""

  # Use media URL if available, otherwise construct APOD page URL from date
  local display_url=""
  if [ -n "$url" ] && [ "$url" != "null" ]; then
    display_url="$url"
  elif [ -n "$apod_date" ] && [ "$apod_date" != "null" ]; then
    # Construct APOD page URL: https://apod.nasa.gov/apod/apYYMMDD.html
    local formatted_date=$(echo "$apod_date" | sed 's/-//g' | cut -c3-)
    display_url="https://apod.nasa.gov/apod/ap${formatted_date}.html"
  else
    display_url="https://apod.nasa.gov/apod/astropix.html"
  fi

  echo_cyan "  🔗 $display_url"
  echo ""
}

###############################################################################
# Cat of the Day (The Cat API)
###############################################################################

_get_cat_image_file() {
  echo "${GOODMORNING_CONFIG_DIR}/cache/cat_of_day.jpg"
}

_get_cat_cache_file() {
  echo "${GOODMORNING_CONFIG_DIR}/cache/cat_of_day.json"
}

_fetch_cat() {
  local cat_cache_file="$(_get_cat_cache_file)"

  if [[ -f "$cat_cache_file" ]] && _is_cache_valid "$cat_cache_file"; then
    cat "$cat_cache_file"
    return 0
  fi

  local api_response
  api_response=$(curl -s --max-time 10 "https://api.thecatapi.com/v1/images/search?limit=1" 2>/dev/null)

  if [[ -z "$api_response" ]]; then
    return 1
  fi

  local image_url
  image_url=$(printf '%s' "$api_response" | jq -r '.[0].url // empty' 2>/dev/null)

  if [[ -z "$image_url" ]]; then
    return 1
  fi

  mkdir -p "$(dirname "$cat_cache_file")"
  printf '%s' "$api_response" | jq '.[0]' > "$cat_cache_file"
  cat "$cat_cache_file"
  return 0
}

show_cat_of_day() {
  if [[ -n "$GOODMORNING_FORCE_OFFLINE" ]]; then
    return 0
  fi

  print_section "🐱 Cat of the Day" "cyan"

  local cat_image_data
  cat_image_data=$(fetch_with_spinner "Fetching cat..." _fetch_cat)

  if [[ -z "$cat_image_data" ]]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch cat image')"
    return 0
  fi

  local image_url
  local image_width
  local image_height
  local cached_image_file

  image_url=$(printf '%s' "$cat_image_data" | jq -r '.url' 2>/dev/null)
  image_width=$(printf '%s' "$cat_image_data" | jq -r '.width // empty' 2>/dev/null)
  image_height=$(printf '%s' "$cat_image_data" | jq -r '.height // empty' 2>/dev/null)
  cached_image_file="$(_get_cat_image_file)"

  if [[ ! -f "$cached_image_file" ]] || ! _is_cache_valid "$cached_image_file"; then
    _download_image "$image_url" "$cached_image_file"
  fi

  if _iterm_can_display_images && _validate_image_file "$cached_image_file"; then
    _display_image_iterm "$cached_image_file"
    echo ""
  fi

  if [[ -n "$image_width" ]] && [[ -n "$image_height" ]]; then
    echo_gray "  ${image_width}x${image_height}"
  fi

  echo_cyan "  🔗 $image_url"
  echo ""
}
