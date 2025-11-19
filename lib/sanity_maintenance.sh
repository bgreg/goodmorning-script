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
source "${SCRIPT_DIR}/lib/sitemap.sh"

# Internal function to fetch XKCD data (called by _fetch_random_xkcd_with_spinner)
_fetch_xkcd_data() {
  # Get latest comic number
  local latest=$(curl -s --max-time 10 "https://xkcd.com/info.0.json" 2>/dev/null | jq -r '.num' 2>/dev/null)

  if [ -z "$latest" ] || [ "$latest" = "null" ]; then
    echo ""
    return 1
  fi

  # Pick random comic (skip first few which might not exist)
  local random_num=$((RANDOM % (latest - 1) + 1))

  # Fetch that comic's info
  local comic_data=$(curl -s --max-time 10 "https://xkcd.com/${random_num}/info.0.json" 2>/dev/null)

  if [ -n "$comic_data" ]; then
    local title=$(echo "$comic_data" | jq -r '.title' 2>/dev/null)
    local url="https://xkcd.com/${random_num}/"
    echo "${title}|${url}"
  fi
}

# Fetch random XKCD comic using their API
_fetch_random_xkcd() {
  local result=$(fetch_with_spinner "Fetching XKCD..." _fetch_xkcd_data)
  echo "$result"
}

# Display a resource from a specific category
_show_from_category() {
  local json_file="$1"
  local category="$2"

  # Get items in that category
  local item_count=$(jq ".categories.${category} | length" "$json_file" 2>/dev/null)
  [ -z "$item_count" ] || [ "$item_count" -eq 0 ] && return 1

  local random_index=$((RANDOM % item_count))
  local title=$(jq -r ".categories.${category}[$random_index].title" "$json_file")
  local url=$(jq -r ".categories.${category}[$random_index].url" "$json_file")

  # Title case the category name
  local category_title=$(echo "$category" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

  # Handle special URL types
  if [[ "$url" == "xkcd:random" ]]; then
    local xkcd_result=$(_fetch_random_xkcd)
    if [ -n "$xkcd_result" ]; then
      local xkcd_title="${xkcd_result%%|*}"
      url="${xkcd_result#*|}"
      echo_yellow "  ${category_title}:"
      echo_cyan "    XKCD: ${xkcd_title}"
      echo_gray "    ${url}"
      [[ "$OPEN_LINKS" == "true" ]] && open "$url"
      return 0
    else
      echo_yellow "  Failed to fetch XKCD"
      return 1
    fi
  fi

  echo_yellow "  ${category_title}:"
  echo_cyan "    ${title}"
  echo_gray "    ${url}"

  if [[ "$url" =~ ^https?:// ]] && [[ "$OPEN_LINKS" == "true" ]]; then
    open "$url"
  fi

  return 0
}

# Display a categorized resource (excluding comics)
_show_non_comic_resource() {
  local json_file="$1"

  # Get list of category names excluding comics
  local categories=(${(f)"$(jq -r '.categories | keys[] | select(. != "comics")' "$json_file" 2>/dev/null)"})
  [ ${#categories[@]} -eq 0 ] && return 1

  # Pick random category
  local category="${categories[$((RANDOM % ${#categories[@]} + 1))]}"

  _show_from_category "$json_file" "$category"
}

show_sanity_maintenance() {
  print_section "🧘 Sanity Maintenance:"

  # Find JSON file
  local json_file="${GOODMORNING_CONFIG_DIR}/sanity-maintenance-sources.json"
  [ ! -f "$json_file" ] && json_file="${SCRIPT_DIR}/sanity-maintenance-sources.json"

  if [ ! -f "$json_file" ]; then
    echo_yellow "  Sources file not found"
    show_setup_message "Create sanity-maintenance-sources.json with entertainment links"
    echo ""
    return
  fi

  echo ""

  # Check if comics category has entries
  local comics_count=$(jq '.categories.comics | length' "$json_file" 2>/dev/null)

  if [ -n "$comics_count" ] && [ "$comics_count" -gt 0 ]; then
    # Show one comic
    if ! _show_from_category "$json_file" "comics"; then
      echo_yellow "  No comics available"
    fi
    echo ""

    # Show one from other categories
    if ! _show_non_comic_resource "$json_file"; then
      echo_yellow "  No other sources available"
    fi
  else
    # No comics, show one random item from any category
    local categories=(${(f)"$(jq -r '.categories | keys[]' "$json_file" 2>/dev/null)"})
    if [ ${#categories[@]} -gt 0 ]; then
      local category="${categories[$((RANDOM % ${#categories[@]} + 1))]}"
      if ! _show_from_category "$json_file" "$category"; then
        echo_yellow "  No sources available"
      fi
    else
      echo_yellow "  No sources available"
    fi
  fi

  echo ""
}
