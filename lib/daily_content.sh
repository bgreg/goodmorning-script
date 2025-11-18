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

  local all_countries=$(curl -s "https://restcountries.com/v3.1/all" 2>/dev/null)

  if [ -z "$all_countries" ]; then
    return 1
  fi

  local total_countries=$(echo "$all_countries" | grep -o '"name"' | wc -l)
  local random_index=$((RANDOM % total_countries))

  local country_data=$(echo "$all_countries" | jq ".[$random_index]" 2>/dev/null)

  if [ -n "$country_data" ]; then
    mkdir -p "$(dirname "$cache_file")"
    echo "$country_data" > "$cache_file"
    echo "$country_data"
    return 0
  fi

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

  local name=$(echo "$country_data" | jq -r '.name.common' 2>/dev/null)
  local official_name=$(echo "$country_data" | jq -r '.name.official' 2>/dev/null)
  local capital=$(echo "$country_data" | jq -r '.capital[0]? // "N/A"' 2>/dev/null)
  local region=$(echo "$country_data" | jq -r '.region' 2>/dev/null)
  local subregion=$(echo "$country_data" | jq -r '.subregion // "N/A"' 2>/dev/null)
  local population=$(echo "$country_data" | jq -r '.population' 2>/dev/null)
  local area=$(echo "$country_data" | jq -r '.area' 2>/dev/null)
  local flag=$(echo "$country_data" | jq -r '.flag' 2>/dev/null)

  local languages=$(echo "$country_data" | jq -r '.languages // {} | to_entries | .[].value' 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
  local currencies=$(echo "$country_data" | jq -r '.currencies // {} | to_entries | .[].value.name' 2>/dev/null | tr '\n' ', ' | sed 's/,$//')

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
# Word of the Day (Merriam-Webster)
###############################################################################

_get_word_cache_file() {
  echo "${GOODMORNING_CONFIG_DIR}/cache/word_of_day.json"
}

_fetch_word_of_day() {
  local cache_file="$(_get_word_cache_file)"

  if _is_cache_valid "$cache_file"; then
    cat "$cache_file"
    return 0
  fi

  local word_data=$(curl -s "https://www.merriam-webster.com/word-of-the-day" 2>/dev/null)

  if [ -z "$word_data" ]; then
    return 1
  fi

  local word=$(echo "$word_data" | grep -o '<h1[^>]*>[^<]*</h1>' | sed 's/<[^>]*>//g' | head -1)
  local definition=$(echo "$word_data" | grep -o '<div class="wod-definition-container"[^>]*>.*</div>' | sed 's/<[^>]*>//g' | head -1)

  if [ -n "$word" ]; then
    mkdir -p "$(dirname "$cache_file")"
    echo "{\"word\":\"$word\",\"definition\":\"$definition\"}" > "$cache_file"
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

  local word=$(echo "$word_data" | jq -r '.word' 2>/dev/null)
  local definition=$(echo "$word_data" | jq -r '.definition' 2>/dev/null)

  echo ""
  echo_cyan "  📖 $(echo_green "$word")"
  echo ""
  echo "  $definition" | fold -s -w 70 | sed 's/^/  /'
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
  local article_data=$(curl -s "$wiki_url" 2>/dev/null)

  if [ -z "$article_data" ]; then
    return 1
  fi

  mkdir -p "$(dirname "$cache_file")"
  echo "$article_data" > "$cache_file"
  echo "$article_data"
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

  local title=$(echo "$article_data" | jq -r '.tfa.title' 2>/dev/null)
  local extract=$(echo "$article_data" | jq -r '.tfa.extract' 2>/dev/null)
  local url=$(echo "$article_data" | jq -r '.tfa.content_urls.desktop.page' 2>/dev/null)

  echo ""
  echo_cyan "  📰 $(echo_green "$title")"
  echo ""
  echo "$extract" | fold -s -w 70 | sed 's/^/  /'
  echo ""
  echo_cyan "  🔗 $url"
  echo ""
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
  echo "$apod_data" > "$cache_file"
  echo "$apod_data"
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

  local title=$(echo "$apod_data" | jq -r '.title' 2>/dev/null)
  local explanation=$(echo "$apod_data" | jq -r '.explanation' 2>/dev/null)
  local url=$(echo "$apod_data" | jq -r '.url' 2>/dev/null)
  local media_type=$(echo "$apod_data" | jq -r '.media_type' 2>/dev/null)
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
  echo_cyan "  🔗 $url"
  echo ""
}
