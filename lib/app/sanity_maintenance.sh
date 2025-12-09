#!/usr/bin/env zsh

###############################################################################
# Sanity Maintenance Functions
#
# Provides daily entertainment links from comics, humor sites, forums, etc.
# Organized by categories for better variety.
#
# JSON Format (sanity-maintenance-sources.json):
#   {
#     "sitemaps": [{ "title": "Name", "sitemap": "url" }],
#     "categories": {
#       "comics": [{ "title": "Name", "url": "url" }],
#       "satire": [{ "title": "Name", "url": "url" }],
#       "forums": [{ "title": "Name", "url": "url" }]
#     }
#   }
###############################################################################

# Source shared sitemap utilities
source "${SCRIPT_DIR}/lib/app/sitemap.sh"

_fetch_xkcd_data() {
  local latest=$(fetch_url "https://xkcd.com/info.0.json" | jq -r '.num' 2>/dev/null)

  if [ -z "$latest" ] || [ "$latest" = "null" ]; then
    show_new_line
    return 1
  fi

  local random_num=$(($(random_in_range $((latest - 1))) + 1))
  local comic_data=$(fetch_url "https://xkcd.com/${random_num}/info.0.json")

  if [ -n "$comic_data" ]; then
    local title=$(echo "$comic_data" | jq -r '.title' 2>/dev/null)
    local url="https://xkcd.com/${random_num}/"
    echo "${title}|${url}"
  fi
}

_fetch_random_xkcd() {
  local result=$(fetch_with_spinner "Fetching XKCD..." _fetch_xkcd_data)
  echo "$result"
}

_handle_xkcd_random_url() {
  local category="$1"
  local category_title=$(to_title_case "$category")

  local xkcd_result=$(_fetch_random_xkcd)
  if [ -n "$xkcd_result" ]; then
    local xkcd_title="${xkcd_result%%|*}"
    local url="${xkcd_result#*|}"
    echo_yellow "  ${category_title}:"
    echo_cyan "    XKCD: ${xkcd_title}"
    echo_gray "    ${url}"
    [[ "$OPEN_LINKS" == "true" ]] && open "$url"
    return 0
  else
    echo_yellow "  Failed to fetch XKCD"
    return 1
  fi
}

_show_from_category() {
  local json_file="$1"
  local category="$2"

  local item_count=$(jq ".categories.${category} | length" "$json_file" 2>/dev/null)
  [ -z "$item_count" ] || [ "$item_count" -eq 0 ] && return 1

  local random_index=$(random_in_range "$item_count")
  local title=$(jq -r ".categories.${category}[$random_index].title" "$json_file")
  local url=$(jq -r ".categories.${category}[$random_index].url" "$json_file")

  if [[ "$url" == "xkcd:random" ]]; then
    _handle_xkcd_random_url "$category"
    return $?
  fi

  local category_title=$(to_title_case "$category")
  echo_yellow "  ${category_title}:"
  echo_cyan "    ${title}"
  echo_gray "    ${url}"

  if [[ "$url" =~ ^https?:// ]] && [[ "$OPEN_LINKS" == "true" ]]; then
    open "$url"
  fi

  return 0
}

_show_random_from_categories() {
  local json_file="$1"
  local jq_filter="$2"

  local categories=(${(f)"$(jq -r "$jq_filter" "$json_file" 2>/dev/null)"})
  [ ${#categories[@]} -eq 0 ] && return 1

  local random_category=$(random_array_element "${categories[@]}")
  _show_from_category "$json_file" "$random_category"
}

_show_non_comic_resource() {
  local json_file="$1"
  _show_random_from_categories "$json_file" '.categories | keys[] | select(. != "comics")'
}

show_sanity_maintenance() {
  print_section "🤪 Sanity Maintenance:"

  local json_file="${GOODMORNING_CONFIG_DIR}/sanity-maintenance-sources.json"
  [ ! -f "$json_file" ] && json_file="${SCRIPT_DIR}/data/sanity-maintenance-sources.json"

  if [ ! -f "$json_file" ]; then
    echo_yellow "  Sources file not found"
    show_setup_message "Create sanity-maintenance-sources.json with entertainment links"
    show_new_line
    return
  fi

  show_new_line

  local comics_count=$(jq '.categories.comics | length' "$json_file" 2>/dev/null)

  if [ -n "$comics_count" ] && [ "$comics_count" -gt 0 ]; then
    if ! _show_from_category "$json_file" "comics"; then
      echo_yellow "  No comics available"
    fi
    show_new_line

    if ! _show_non_comic_resource "$json_file"; then
      echo_yellow "  No other sources available"
    fi
  else
    # No comics, show one random item from any category
    if ! _show_random_from_categories "$json_file" '.categories | keys[]'; then
      echo_yellow "  No sources available"
    fi
  fi
  show_new_line
}