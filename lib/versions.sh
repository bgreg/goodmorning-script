#!/usr/bin/env zsh

###############################################################################
# Version Information Functions
#
# Fetches and displays the latest versions of popular programming languages
# and frameworks using GitHub API and official sources.
#
# Features:
# - Daily caching to minimize API calls
# - Offline mode support
# - Configurable technology list
# - Clean, formatted output
###############################################################################

_get_cache_file() {
  local tech="$1"
  echo "${GOODMORNING_CONFIG_DIR}/cache/versions_${tech}.txt"
}

_is_cache_valid() {
  local cache_file="$1"

  if [ ! -f "$cache_file" ]; then
    return 1
  fi

  local cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
  local max_age=$((24 * 60 * 60))

  [ "$cache_age" -lt "$max_age" ]
}

_fetch_github_version() {
  local repo="$1"
  local cache_file="$2"

  if _is_cache_valid "$cache_file"; then
    cat "$cache_file"
    return 0
  fi

  local api_url="https://api.github.com/repos/${repo}/releases/latest"
  local version=$(curl -s "$api_url" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)

  if [ -n "$version" ]; then
    mkdir -p "$(dirname "$cache_file")"
    echo "$version" > "$cache_file"
    echo "$version"
    return 0
  fi

  return 1
}

_fetch_go_version() {
  local cache_file="$1"

  if _is_cache_valid "$cache_file"; then
    cat "$cache_file"
    return 0
  fi

  local version=$(curl -s "https://go.dev/dl/?mode=json" | grep -o '"version": "[^"]*' | head -1 | cut -d'"' -f4 | sed 's/go//')

  if [ -n "$version" ]; then
    mkdir -p "$(dirname "$cache_file")"
    echo "$version" > "$cache_file"
    echo "$version"
    return 0
  fi

  return 1
}

_fetch_python_version() {
  local cache_file="$1"

  if _is_cache_valid "$cache_file"; then
    cat "$cache_file"
    return 0
  fi

  local version=$(curl -s "https://www.python.org/downloads/" | grep -o 'Download Python [0-9.]*' | head -1 | awk '{print $3}')

  if [ -n "$version" ]; then
    mkdir -p "$(dirname "$cache_file")"
    echo "$version" > "$cache_file"
    echo "$version"
    return 0
  fi

  return 1
}

get_tech_versions() {
  local versions=()

  echo_cyan "Fetching latest versions..."

  local ruby_version=$(_fetch_github_version "ruby/ruby" "$(_get_cache_file ruby)")
  [ -n "$ruby_version" ] && versions+=("Ruby|$ruby_version")

  local rails_version=$(_fetch_github_version "rails/rails" "$(_get_cache_file rails)")
  [ -n "$rails_version" ] && versions+=("Rails|$rails_version")

  local typescript_version=$(_fetch_github_version "microsoft/TypeScript" "$(_get_cache_file typescript)")
  [ -n "$typescript_version" ] && versions+=("TypeScript|$typescript_version")

  local nextjs_version=$(_fetch_github_version "vercel/next.js" "$(_get_cache_file nextjs)")
  [ -n "$nextjs_version" ] && versions+=("Next.js|$nextjs_version")

  local react_version=$(_fetch_github_version "facebook/react" "$(_get_cache_file react)")
  [ -n "$react_version" ] && versions+=("React|$react_version")

  local rust_version=$(_fetch_github_version "rust-lang/rust" "$(_get_cache_file rust)")
  [ -n "$rust_version" ] && versions+=("Rust|$rust_version")

  local go_version=$(_fetch_go_version "$(_get_cache_file go)")
  [ -n "$go_version" ] && versions+=("Go|$go_version")

  local elixir_version=$(_fetch_github_version "elixir-lang/elixir" "$(_get_cache_file elixir)")
  [ -n "$elixir_version" ] && versions+=("Elixir|$elixir_version")

  local phoenix_version=$(_fetch_github_version "phoenixframework/phoenix" "$(_get_cache_file phoenix)")
  [ -n "$phoenix_version" ] && versions+=("Phoenix|$phoenix_version")

  local python_version=$(_fetch_python_version "$(_get_cache_file python)")
  [ -n "$python_version" ] && versions+=("Python|$python_version")

  local django_version=$(_fetch_github_version "django/django" "$(_get_cache_file django)")
  [ -n "$django_version" ] && versions+=("Django|$django_version")

  echo "${versions[@]}"
}

show_tech_versions() {
  if [ -n "$GOODMORNING_FORCE_OFFLINE" ]; then
    return 0
  fi

  print_section "Latest Tech Versions" "cyan"

  local versions=($(get_tech_versions))

  if [ ${#versions[@]} -eq 0 ]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch version information')"
    show_setup_message "$(echo_yellow '    Check your internet connection')"
    return 0
  fi

  local col1_width=15
  local col2_width=15
  local count=0
  local line=""

  for version_info in "${versions[@]}"; do
    local tech=$(echo "$version_info" | cut -d'|' -f1)
    local version=$(echo "$version_info" | cut -d'|' -f2)

    local formatted=$(printf "%-${col1_width}s %-${col2_width}s" "$tech" "$version")

    if [ $((count % 2)) -eq 0 ]; then
      line="  $formatted"
    else
      line="$line  $formatted"
      echo "$line"
      line=""
    fi

    count=$((count + 1))
  done

  if [ -n "$line" ]; then
    echo "$line"
  fi

  echo ""
  echo_green "  💡 Cached for 24 hours"
  echo ""
}
