#!/usr/bin/env zsh

###############################################################################
# Sitemap Utility Functions
#
# Shared functions for fetching and parsing sitemaps.
# Used by learning.sh, sanity_maintenance.sh, and other sections.
###############################################################################

_extract_loc_urls_from_xml() {
  local xml_content="$1"
  echo "$xml_content" | \
    grep -o '<loc>[^<]*</loc>' | \
    sed 's|<loc>\(.*\)</loc>|\1|'
}

_filter_non_content_urls() {
  grep -v '\.\(png\|jpg\|jpeg\|gif\|svg\|css\|js\|xml\|pdf\)$'
}

_filter_documentation_urls() {
  grep -E '(doc|guide|tutorial|reference|api|manual|learn)'
}

fetch_sitemap_urls() {
  local sitemap_url="$1"
  local sitemap_content=$(fetch_url_compressed "$sitemap_url")

  require_non_empty "$sitemap_content" || return 1
  _extract_loc_urls_from_xml "$sitemap_content" | _filter_non_content_urls
}

fetch_doc_sitemap_urls() {
  local sitemap_url="$1"
  local sitemap_content=$(fetch_url_compressed "$sitemap_url")

  require_non_empty "$sitemap_content" || return 1

  local doc_urls=$(_extract_loc_urls_from_xml "$sitemap_content" | _filter_documentation_urls | _filter_non_content_urls)

  if [ -z "$doc_urls" ]; then
    _extract_loc_urls_from_xml "$sitemap_content" | _filter_non_content_urls
  else
    echo "$doc_urls"
  fi
}

extract_title_from_url() {
  local url="$1"
  local title=$(echo "$url" | sed -E 's|.*/([^/]+)/?$|\1|' | \
                sed -E 's/\.(html?|php|aspx?)$//' | \
                tr '_-' ' ')
  to_title_case "$title"
}

# Pick random item from JSON array
pick_random_from_json() {
  local json_file="$1"
  local array_path="$2"  # e.g., ".sitemaps" or ".static"

  local count=$(jq "${array_path} | length" "$json_file" 2>/dev/null)
  [ -z "$count" ] || [ "$count" -eq 0 ] && return 1

  local random_index=$(random_in_range "$count")
  jq -r "${array_path}[$random_index]" "$json_file"
}
