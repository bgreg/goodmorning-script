#!/usr/bin/env zsh

###############################################################################
# Daily Learning Functions
#
# Provides daily learning suggestions from two source types:
# - Sitemaps: Dynamic random page selection from site sitemaps
# - Static: Direct links to documentation pages
#
# JSON Format (learning-sources.json):
#   {
#     "sitemaps": [{ "title": "Name", "sitemap": "url" }],
#     "static": [{ "title": "Name", "url": "url" }]
#   }
###############################################################################

# Source shared sitemap utilities
source "${SCRIPT_DIR}/lib/app/sitemap.sh"

_show_sitemap_resource() {
  local json_file="$1"

  local sitemap_count=$(jq '.sitemaps | length' "$json_file" 2>/dev/null)
  [ -z "$sitemap_count" ] || [ "$sitemap_count" -eq 0 ] && return 1

  local random_index=$(random_in_range "$sitemap_count")
  local title=$(jq -r ".sitemaps[$random_index].title" "$json_file")
  local sitemap=$(jq -r ".sitemaps[$random_index].sitemap" "$json_file")

  local sitemap_content
  sitemap_content=$(fetch_with_spinner "Fetching sitemap..." fetch_doc_sitemap_urls "$sitemap")

  if [ -z "$sitemap_content" ]; then
    echo_yellow "  Failed to fetch from ${title}"
    return 1
  fi

  local -a sitemap_links
  if [[ -n "$sitemap_content" ]]; then
    sitemap_links=("${(@f)sitemap_content}")
  fi

  if [ ${#sitemap_links[@]} -eq 0 ]; then
    echo_yellow "  No links found in ${title}"
    return 1
  fi

  local doc_url=$(random_array_element "${sitemap_links[@]}")
  local doc_title=$(extract_title_from_url "$doc_url")

  echo_cyan "  Topic: ${title}"
  echo_yellow "  ${doc_title}"
  echo_gray "  ${doc_url}"

  if [[ "$doc_url" =~ ^https?:// ]] && [[ "$OPEN_LINKS" == "true" ]]; then
    open "$doc_url"
  fi

  return 0
}

_show_static_resource() {
  local json_file="$1"

  local static_count=$(jq '.static | length' "$json_file" 2>/dev/null)
  [ -z "$static_count" ] || [ "$static_count" -eq 0 ] && return 1

  local random_index=$(random_in_range "$static_count")
  local title=$(jq -r ".static[$random_index].title" "$json_file")
  local url=$(jq -r ".static[$random_index].url" "$json_file")

  echo_cyan "  Topic: ${title}"
  echo_gray "  ${url}"

  if [[ "$url" =~ ^https?:// ]] && [[ "$OPEN_LINKS" == "true" ]]; then
    open "$url"
  fi

  return 0
}

show_daily_learning() {
  print_section "📚 Daily Learning:"

  # Find JSON file
  local json_file="${GOODMORNING_CONFIG_DIR}/learning-sources.json"
  [ ! -f "$json_file" ] && json_file="${SCRIPT_DIR}/data/learning-sources.json"

  if [ ! -f "$json_file" ]; then
    echo_yellow "  Learning sources file not found"
    show_setup_message "Run './setup.sh --section learning' to configure"
    show_new_line
    return
  fi

  # Show one from sitemaps
  show_new_line
  if ! _show_sitemap_resource "$json_file"; then
    echo_yellow "  No sitemap sources available"
  fi

  show_new_line

  # Show one from static
  if ! _show_static_resource "$json_file"; then
    echo_yellow "  No static sources available"
  fi

  show_new_line
}
