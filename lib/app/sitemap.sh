#!/usr/bin/env zsh

###############################################################################
# Sitemap Utility Functions
#
# Shared functions for fetching and parsing sitemaps.
# Used by learning.sh, sanity_maintenance.sh, and other sections.
###############################################################################

# Fetch and parse sitemap URLs
fetch_sitemap_urls() {
  local sitemap_url="$1"
  local urls=()

  # Fetch sitemap and extract <loc> tags
  # Use --compressed to handle gzipped sitemaps automatically
  local sitemap_content=$(curl -s -L --compressed --max-time 10 "$sitemap_url" 2>/dev/null)

  if [ -n "$sitemap_content" ]; then
    # Extract URLs from <loc> tags
    urls=(${(f)"$(echo "$sitemap_content" | \
            grep -o '<loc>[^<]*</loc>' | \
            sed 's|<loc>\(.*\)</loc>|\1|' | \
            grep -v '\.\(png\|jpg\|jpeg\|gif\|svg\|css\|js\|xml\|pdf\)$')"})
  fi

  printf '%s\n' "${urls[@]}"
}

# Fetch sitemap URLs filtered for documentation
fetch_doc_sitemap_urls() {
  local sitemap_url="$1"
  local urls=()

  local sitemap_content=$(curl -s -L --compressed --max-time 10 "$sitemap_url" 2>/dev/null)

  if [ -n "$sitemap_content" ]; then
    # Extract URLs, filter for documentation pages
    urls=(${(f)"$(echo "$sitemap_content" | \
            grep -o '<loc>[^<]*</loc>' | \
            sed 's|<loc>\(.*\)</loc>|\1|' | \
            grep -v '\.\(png\|jpg\|jpeg\|gif\|svg\|css\|js\|xml\|pdf\)$' | \
            grep -E '(doc|guide|tutorial|reference|api|manual|learn)')"})

    # If no filtered URLs, use all URLs
    if [ ${#urls[@]} -eq 0 ]; then
      urls=(${(f)"$(echo "$sitemap_content" | \
              grep -o '<loc>[^<]*</loc>' | \
              sed 's|<loc>\(.*\)</loc>|\1|' | \
              grep -v '\.\(png\|jpg\|jpeg\|gif\|svg\|css\|js\|xml\)$')"})
    fi
  fi

  printf '%s\n' "${urls[@]}"
}

# Extract title from URL
extract_title_from_url() {
  local url="$1"
  # Get last path segment, remove extension, replace dashes/underscores with spaces, title case
  local title=$(echo "$url" | sed -E 's|.*/([^/]+)/?$|\1|' | \
                sed -E 's/\.(html?|php|aspx?)$//' | \
                tr '_-' ' ' | \
                awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
  echo "$title"
}

# Pick random item from JSON array
pick_random_from_json() {
  local json_file="$1"
  local array_path="$2"  # e.g., ".sitemaps" or ".static"

  local count=$(jq "${array_path} | length" "$json_file" 2>/dev/null)
  [ -z "$count" ] || [ "$count" -eq 0 ] && return 1

  local random_index=$((RANDOM % count))
  jq -r "${array_path}[$random_index]" "$json_file"
}
