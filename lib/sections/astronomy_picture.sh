#!/usr/bin/env zsh

###############################################################################
# NASA Astronomy Picture of the Day Section
###############################################################################

# Section dependencies
SECTION_DEPS_TOOLS=(curl jq)
SECTION_DEPS_NETWORK=true

fetch_apod() {
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

  print -r -- "$apod_data"
  return 0
}

show_apod() {
  if [ -n "$GOODMORNING_FORCE_OFFLINE" ]; then
    return 0
  fi

  print_section "Astronomy Picture of the Day" "cyan"

  local apod_data=$(fetch_with_spinner "Fetching APOD..." fetch_apod)

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

  echo ""
  echo_cyan "  🌌 $(echo_green "$title")"
  echo ""

  if [ "$media_type" = "image" ]; then
    if iterm_can_display_images; then
      echo "  $(echo_yellow 'Image available at URL below')"
      echo ""
    fi
  fi

  echo "$explanation" | fold -s -w 70 | sed 's/^/  /'
  echo ""

  local display_url=""
  if [ -n "$url" ] && [ "$url" != "null" ]; then
    display_url="$url"
  elif [ -n "$apod_date" ] && [ "$apod_date" != "null" ]; then
    local formatted_date=$(echo "$apod_date" | sed 's/-//g' | cut -c3-)
    display_url="https://apod.nasa.gov/apod/ap${formatted_date}.html"
  else
    display_url="https://apod.nasa.gov/apod/astropix.html"
  fi

  echo_cyan "  🔗 $display_url"
  echo ""
}
