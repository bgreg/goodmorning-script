#!/usr/bin/env zsh

###############################################################################
# Cat of the Day Section
#
# Displays random cat image from The Cat API
###############################################################################

# Section dependencies
SECTION_DEPS_TOOLS=(curl jq)
SECTION_DEPS_NETWORK=true

fetch_cat() {
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

  printf '%s' "$api_response" | jq '.[0]'
  return 0
}

show_cat_of_day() {
  if [[ -n "$GOODMORNING_FORCE_OFFLINE" ]]; then
    return 0
  fi

  print_section "🐱 Cat of the Day" "cyan"

  local cat_image_data
  cat_image_data=$(fetch_with_spinner "Fetching cat..." fetch_cat)

  if [[ -z "$cat_image_data" ]]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch cat image')"
    return 0
  fi

  local image_url
  local image_width
  local image_height

  image_url=$(printf '%s' "$cat_image_data" | jq -r '.url' 2>/dev/null)
  image_width=$(printf '%s' "$cat_image_data" | jq -r '.width // empty' 2>/dev/null)
  image_height=$(printf '%s' "$cat_image_data" | jq -r '.height // empty' 2>/dev/null)

  if [[ -n "$image_width" ]] && [[ -n "$image_height" ]]; then
    echo_gray "  ${image_width}x${image_height}"
  fi

  echo_cyan "  🔗 $image_url"
  echo ""
}
