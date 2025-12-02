#!/usr/bin/env zsh

###############################################################################
# Wikipedia Featured Article Section
#
# Displays today's featured Wikipedia article
###############################################################################

# Section dependencies
SECTION_DEPS_TOOLS=(curl jq perl)
SECTION_DEPS_NETWORK=true

fetch_wikipedia_featured() {
  local today=$(date +"%Y/%m/%d")
  local wiki_url="https://en.wikipedia.org/api/rest_v1/feed/featured/${today}"
  local article_data=$(curl -s -H "Api-User-Agent: GoodmorningScript/1.0 (personal productivity tool)" "$wiki_url" 2>/dev/null)

  if [ -z "$article_data" ]; then
    return 1
  fi

  # Sanitize control characters using perl
  local sanitized_data=$(printf '%s' "$article_data" | perl -pe 's/[\x00-\x08\x0b\x0c\x0e-\x1f]//g' 2>/dev/null)

  print -r -- "$sanitized_data"
  return 0
}

show_wikipedia_featured() {
  if [ -n "$GOODMORNING_FORCE_OFFLINE" ]; then
    return 0
  fi

  print_section "Wikipedia Featured Article" "cyan"

  local article_data=$(fetch_with_spinner "Fetching article..." fetch_wikipedia_featured)

  if [ -z "$article_data" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch Wikipedia featured article')"
    return 0
  fi

  local title=$(printf '%s' "$article_data" | jq -r '.tfa.title' 2>/dev/null)
  local extract=$(printf '%s' "$article_data" | jq -r '.tfa.extract' 2>/dev/null)
  local url=$(printf '%s' "$article_data" | jq -r '.tfa.content_urls.desktop.page' 2>/dev/null)

  title=$(safe_display "$title" "")
  extract=$(safe_display "$extract" "")
  url=$(safe_display "$url" "")

  if [ -z "$title" ] && [ -z "$extract" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Wikipedia article data unavailable')"
    return 0
  fi

  echo ""
  if [ -n "$title" ]; then
    echo_cyan "  📰 $(echo_green "$title")"
    echo ""
  fi
  if [ -n "$extract" ]; then
    echo "$extract" | fold -s -w 70 | sed 's/^/  /'
    echo ""
  fi
  if [ -n "$url" ]; then
    echo_cyan "  🔗 $url"
    echo ""
  fi
}
