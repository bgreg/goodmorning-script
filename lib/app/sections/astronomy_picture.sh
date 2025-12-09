#!/usr/bin/env zsh

###############################################################################
# NASA Astronomy Picture of the Day Section
###############################################################################

fetch_apod() {
  local api_key="${GOODMORNING_NASA_API_KEY:-DEMO_KEY}"
  local apod_url="https://api.nasa.gov/planetary/apod?api_key=${api_key}"
  local apod_data=$(fetch_url "$apod_url")

  require_non_empty "$apod_data" || return 1
  [[ -n "$(jq_extract "$apod_data" '.error')" ]] && return 1
  require_non_empty "$(jq_extract "$apod_data" '.title')" || return 1

  print -r -- "$apod_data"
  return 0
}

show_apod() {
  print_section "Astronomy Picture of the Day" "cyan"

  local apod_data=$(fetch_with_spinner "Fetching APOD..." fetch_apod)

  if [ -z "$apod_data" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch APOD')"
    show_setup_message "$(echo_yellow '    Set GOODMORNING_NASA_API_KEY for higher rate limits')"
    return 0
  fi

  local title=$(jq_extract "$apod_data" '.title')
  local explanation=$(jq_extract "$apod_data" '.explanation')
  local url=$(jq_extract "$apod_data" '.url')
  local apod_date=$(jq_extract "$apod_data" '.date')
  local media_type=$(jq_extract "$apod_data" '.media_type')

  show_new_line
  echo_cyan "  🌌 $(echo_green "$title")"
  show_new_line

  # Download and display image if available
  if [ "$media_type" = "image" ]; then
    local image_file="${TMPDIR:-/tmp}/apod_image_$$.jpg"
    download_image "$url" "$image_file" >/dev/null 2>&1

    # Display image if in iTerm2 and image is valid
    if iterm_can_display_images && validate_image_file "$image_file"; then
      echo "  $(echo_yellow 'Displaying image in iTerm...')"
      show_new_line
      display_image_iterm "$image_file"
      show_new_line
    fi
  fi

  echo "$explanation" | fold -s -w 70 | sed 's/^/  /'
  show_new_line

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
  show_new_line
}
