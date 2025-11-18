#!/usr/bin/env zsh

###############################################################################
# Daily Learning Functions
#
# Provides daily learning suggestions from configurable URL sources
# organized by topic categories. Supports both static URLs and dynamic
# sitemap fetching.
#
# File Format (learning-sources.txt):
#   [Category Name]
#   sitemap:https://example.com/sitemap.xml
#   URL|Title
#
#   [Another Category]
#   URL|Title
###############################################################################

# Fetch and parse sitemap URLs
_fetch_sitemap_urls() {
  local sitemap_url="$1"
  local urls=()

  # Fetch sitemap and extract <loc> tags
  local sitemap_content=$(curl -s -L --max-time 5 "$sitemap_url" 2>/dev/null)

  if [ -n "$sitemap_content" ]; then
    # Extract URLs from <loc> tags, filter for documentation pages
    urls=($(echo "$sitemap_content" | \
            grep -o '<loc>[^<]*</loc>' | \
            sed 's|<loc>\(.*\)</loc>|\1|' | \
            grep -v '\.\(png\|jpg\|jpeg\|gif\|svg\|css\|js\|xml\|pdf\)$' | \
            grep -E '(doc|guide|tutorial|reference|api|manual|learn)'))

    # If no filtered URLs, use all URLs from sitemap
    if [ ${#urls[@]} -eq 0 ]; then
      urls=($(echo "$sitemap_content" | \
              grep -o '<loc>[^<]*</loc>' | \
              sed 's|<loc>\(.*\)</loc>|\1|' | \
              grep -v '\.\(png\|jpg\|jpeg\|gif\|svg\|css\|js\|xml\)$'))
    fi
  fi

  printf '%s\n' "${urls[@]}"
}

# Extract title from URL
_extract_title_from_url() {
  local url="$1"
  # Get last path segment, remove extension, replace dashes/underscores with spaces, title case
  local title=$(echo "$url" | sed -E 's|.*/([^/]+)/?$|\1|' | \
                sed -E 's|\.(html?|php|aspx?)$||' | \
                tr '-_' ' ' | \
                awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
  echo "$title"
}

show_daily_learning() {
  print_section "📚 Daily Learning:"

  if [ -f "$LEARNING_SOURCES_FILE" ]; then
    local -A categories
    local -A sitemap_urls
    local current_category=""

    # Parse learning sources file
    while IFS= read -r line; do
      [[ -z "$line" || "$line" =~ "^#" ]] && continue

      if [[ "$line" =~ "^\[(.*)\]$" ]]; then
        current_category="${match[1]}"
        categories[$current_category]=""
        sitemap_urls[$current_category]=""
      elif [[ -n "$current_category" && "$line" =~ "^sitemap:(.+)$" ]]; then
        sitemap_urls[$current_category]="${match[1]}"
      elif [[ -n "$current_category" && "$line" =~ "^(https?://[^|]+)\|(.+)$" ]]; then
        local url="${match[1]}"
        local title="${match[2]}"
        if [ -z "${categories[$current_category]}" ]; then
          categories[$current_category]="${url}|${title}"
        else
          categories[$current_category]="${categories[$current_category]}"$'\n'"${url}|${title}"
        fi
      fi
    done < "$LEARNING_SOURCES_FILE"

    if [ ${#categories[@]} -gt 0 ] || [ ${#sitemap_urls[@]} -gt 0 ]; then
      # Select random category
      local all_categories=(${(@k)categories} ${(@k)sitemap_urls})
      local random_category="${all_categories[$((RANDOM % ${#all_categories[@]} + 1))]}"

      local doc_url=""
      local doc_title=""

      # Check if category uses sitemap
      if [ -n "${sitemap_urls[$random_category]}" ]; then
        local sitemap="${sitemap_urls[$random_category]}"
        echo_gray "  Fetching from sitemap..."

        local -a sitemap_links
        sitemap_links=(${(f)"$(_fetch_sitemap_urls "$sitemap")"})

        if [ ${#sitemap_links[@]} -gt 0 ]; then
          doc_url="${sitemap_links[$((RANDOM % ${#sitemap_links[@]} + 1))]}"
          doc_title=$(_extract_title_from_url "$doc_url")
        else
          echo_yellow "  Failed to fetch sitemap URLs"
          return
        fi
      else
        # Use static URLs
        local -a links
        links=("${(@f)categories[$random_category]}")

        if [ ${#links[@]} -gt 0 ]; then
          local random_link="${links[$((RANDOM % ${#links[@]} + 1))]}"
          doc_url="${random_link%%|*}"
          doc_title="${random_link#*|}"
        else
          echo_yellow "  No learning resources found in category: ${random_category}"
          return
        fi
      fi

      # Display selection
      if [ -n "$doc_url" ]; then
        echo_cyan "  Topic: ${random_category}"
        echo_yellow "  ${doc_title}"
        echo_gray "  ${doc_url}\n"

        if [[ "$doc_url" =~ ^https?:// ]]; then
          open "$doc_url"
        else
          echo_warning "Skipping invalid URL format: ${doc_url}"
        fi
      fi
    else
      echo_yellow "  No learning categories found in ${LEARNING_SOURCES_FILE}"
      show_setup_message "Create categories with format:"
      show_setup_message "  [Category Name]"
      show_setup_message "  sitemap:https://example.com/sitemap.xml"
      show_setup_message "  or URL|Title"
    fi
  else
    echo_yellow "  Learning sources file not found: ${LEARNING_SOURCES_FILE}"
    show_setup_message "Run './setup.sh --reconfigure' to set up learning sources"
  fi

  echo ""
}
