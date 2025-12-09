#!/usr/bin/env zsh

###############################################################################
# Cat of the Day Section
#
# Displays random cat image from The Cat API
###############################################################################

fetch_cat() {
  local api_response=$(fetch_url "https://api.thecatapi.com/v1/images/search?limit=1")

  require_non_empty "$api_response" || return 1
  require_non_empty "$(jq_extract "$api_response" '.[0].url')" || return 1

  printf '%s' "$api_response" | jq '.[0]'
  return 0
}

show_cat_of_day() {
  print_section "🐱 Cat of the Day" "cyan"

  local cat_image_data=$(fetch_with_spinner "Fetching cat..." fetch_cat)

  if [[ -z "$cat_image_data" ]]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch cat image')"
    return 0
  fi

  local image_url=$(jq_extract "$cat_image_data" '.url')
  local image_width=$(jq_extract "$cat_image_data" '.width')
  local image_height=$(jq_extract "$cat_image_data" '.height')

  if [[ -n "$image_width" ]] && [[ -n "$image_height" ]]; then
    echo_gray "  ${image_width}x${image_height}"
    show_new_line
  fi

  # Download and display image
  local image_file="${TMPDIR:-/tmp}/cat_of_day_$$.jpg"
  download_image "$image_url" "$image_file" >/dev/null 2>&1

  # Display image if in iTerm2 and image is valid
  if iterm_can_display_images && validate_image_file "$image_file"; then
    echo "  $(echo_yellow 'Displaying image in iTerm...')"
    show_new_line
    display_image_iterm "$image_file"
    show_new_line
  fi

  echo_cyan "  🔗 $image_url"
  show_new_line
}
