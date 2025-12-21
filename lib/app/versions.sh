#!/usr/bin/env zsh

###############################################################################
# Version Information Functions
#
# Fetches and displays the latest versions of popular programming languages
# and frameworks using GitHub API and official sources.
###############################################################################

_fetch_github_version() {
  local repo="$1"
  local api_url="https://api.github.com/repos/${repo}/releases/latest"
  curl -s "$api_url" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4
}

_fetch_go_version() {
  curl -s "https://go.dev/dl/?mode=json" | grep -o '"version": "[^"]*' | head -1 | cut -d'"' -f4 | sed 's/go//'
}

_fetch_python_version() {
  curl -s "https://www.python.org/downloads/" | grep -o 'Download Python [0-9.]*' | head -1 | awk '{print $3}'
}

_fetch_node_version() {
  curl -s "https://nodejs.org/dist/index.json" | grep -o '"version":"[^"]*' | head -1 | cut -d'"' -f4
}

get_tech_versions() {
  local versions=()

  local ruby_version=$(_fetch_github_version "ruby/ruby")
  [ -n "$ruby_version" ] && versions+=("Ruby|$ruby_version")

  local rails_version=$(_fetch_github_version "rails/rails")
  [ -n "$rails_version" ] && versions+=("Rails|$rails_version")

  local typescript_version=$(_fetch_github_version "microsoft/TypeScript")
  [ -n "$typescript_version" ] && versions+=("TypeScript|$typescript_version")

  local node_version=$(_fetch_node_version)
  [ -n "$node_version" ] && versions+=("Node.js|$node_version")

  local nextjs_version=$(_fetch_github_version "vercel/next.js")
  [ -n "$nextjs_version" ] && versions+=("Next.js|$nextjs_version")

  local react_version=$(_fetch_github_version "facebook/react")
  [ -n "$react_version" ] && versions+=("React|$react_version")

  local rust_version=$(_fetch_github_version "rust-lang/rust")
  [ -n "$rust_version" ] && versions+=("Rust|$rust_version")

  local go_version=$(_fetch_go_version)
  [ -n "$go_version" ] && versions+=("Go|$go_version")

  local elixir_version=$(_fetch_github_version "elixir-lang/elixir")
  [ -n "$elixir_version" ] && versions+=("Elixir|$elixir_version")

  local phoenix_version=$(_fetch_github_version "phoenixframework/phoenix")
  [ -n "$phoenix_version" ] && versions+=("Phoenix|$phoenix_version")

  local python_version=$(_fetch_python_version)
  [ -n "$python_version" ] && versions+=("Python|$python_version")

  local django_version=$(_fetch_github_version "django/django")
  [ -n "$django_version" ] && versions+=("Django|$django_version")

  printf '%s\n' "${versions[@]}"
}

show_tech_versions() {
  if [ -n "$GOODMORNING_FORCE_OFFLINE" ]; then
    return 0
  fi

  print_section "Latest Tech Versions" "cyan"

  local versions_output=$(fetch_with_spinner "Fetching versions..." get_tech_versions)
  local versions=(${(f)versions_output})

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

  show_new_line
}
