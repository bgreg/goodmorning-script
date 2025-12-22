#!/usr/bin/env zsh

set -e

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
DEFAULT_INSTALL_DIR="$HOME/.config/zsh/scripts"
DEFAULT_CONFIG_DIR="$HOME/.config/goodmorning"
INSTALL_DIR="${GOODMORNING_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
CONFIG_DIR="${GOODMORNING_CONFIG_DIR:-$DEFAULT_CONFIG_DIR}"
CONFIG_FILE="$CONFIG_DIR/config.sh"

# Source centralized color functions
source "$SCRIPT_DIR/lib/app/colors.sh"

print_success() {
  echo_green "✓ $1"
}

print_error() {
  echo_red "✗ $1"
}

print_info() {
  echo_cyan "→ $1"
}

print_warning() {
  echo_yellow "⚠️  $1"
}

print_header() {
  show_new_line
  echo_cyan "════════════════════════════════════════"
  echo_cyan "  $1"
  echo_cyan "════════════════════════════════════════"
}

section_box() {
  local title="$1"
  local width=50
  local padding=$(( (width - ${#title} - 2) / 2 ))
  local padding_right=$(( width - ${#title} - 2 - padding ))

  show_new_line
  echo_yellow "┌$(printf '─%.0s' {1..50})┐"
  echo_yellow "│$(printf ' %.0s' $(seq 1 $padding))$title$(printf ' %.0s' $(seq 1 $padding_right)) │"
  echo_yellow "└$(printf '─%.0s' {1..50})┘"
  show_new_line
}

###############################################################################
# Section: System Requirements
###############################################################################
setup_section_system() {
  local interactive="${1:-true}"

  print_header "🔍 System Requirements Check"

  if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script requires macOS"
    echo_yellow "Current OS: $OSTYPE"
    exit 1
  fi
  print_success "Running on macOS 🍎"

  local missing_required=()
  local missing_optional=()

  show_new_line
  echo_cyan "📦 Checking required dependencies..."

  if ! command -v curl &> /dev/null; then
    missing_required+=("curl")
    print_error "curl not found (required)"
  else
    print_success "curl found"
  fi

  if ! command -v git &> /dev/null; then
    missing_required+=("git")
    print_error "git not found (required)"
  else
    print_success "git found"
  fi

  if ! command -v jq &> /dev/null; then
    missing_required+=("jq")
    print_error "jq not found (required for JSON parsing)"
  else
    print_success "jq found"
  fi

  show_new_line
  echo_cyan "🔧 Checking optional dependencies..."

  if ! command -v brew &> /dev/null; then
    missing_optional+=("brew")
    print_warning "Homebrew not found (recommended for updates)"
  else
    print_success "Homebrew found 🍺"
  fi

  if ! command -v figlet &> /dev/null; then
    missing_optional+=("figlet")
    print_warning "figlet not found (needed for custom banners)"
  else
    print_success "figlet found 🎨"
  fi

  if ! command -v icalBuddy &> /dev/null; then
    missing_optional+=("icalBuddy")
    print_warning "icalBuddy not found (needed for calendar/reminders)"
  else
    print_success "icalBuddy found 📅"
  fi

  if ! command -v claude &> /dev/null; then
    missing_optional+=("claude")
    print_warning "Claude Code not found (needed for learning tips)"
  else
    print_success "Claude Code found 🤖"
  fi

  if ! command -v gh &> /dev/null; then
    missing_optional+=("gh")
    print_warning "GitHub CLI not found (needed for GitHub notifications)"
  else
    print_success "GitHub CLI found 🐙"
  fi

  if [ ${#missing_required[@]} -gt 0 ]; then
    show_new_line
    echo_red "Missing required dependencies:"
    for dep in "${missing_required[@]}"; do
      echo "  - $dep"
    done
    if command -v brew &> /dev/null; then
      show_new_line
      echo_cyan "Install with:"
      for dep in "${missing_required[@]}"; do
        echo_green "  brew install $dep"
      done
    fi
    exit 1
  fi

  if [ ${#missing_optional[@]} -gt 0 ] && [ "$interactive" = "true" ]; then
    show_new_line
    echo_yellow "Missing optional dependencies:"
    for dep in "${missing_optional[@]}"; do
      echo "  - $dep"
    done

    if command -v brew &> /dev/null; then
      show_new_line
      echo_cyan "Install missing optional dependencies with Homebrew?"
      echo_gray "  (y = install now, Enter/n = skip)"
      show_new_line
      echo_green -n "Install now? [y/N]: "
      read -r install_deps

      if [[ $install_deps =~ ^[Yy]$ ]]; then
        for dep in "${missing_optional[@]}"; do
          case "$dep" in
            "jq") brew install jq ;;
            "figlet") brew install figlet ;;
            "icalBuddy") brew install ical-buddy ;;
            "claude")
              echo_cyan "Install Claude Code with:"
              echo_green "  npm install -g @anthropic-ai/claude-code"
              ;;
            "gh") brew install gh ;;
          esac
        done
      fi
    fi
  fi

  show_new_line
}

###############################################################################
# Section: Basic Configuration
###############################################################################
setup_section_basic() {
  print_header "⚙️  Basic Configuration"

  local current_user_name=""
  local current_enable_tts=""
  local current_config_dir=""

  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE" 2>/dev/null
    current_user_name="${GOODMORNING_USER_NAME:-}"
    current_enable_tts="${GOODMORNING_ENABLE_TTS:-false}"
    current_config_dir="${GOODMORNING_CONFIG_DIR:-}"
  fi

  # Config directory
  show_new_line
  section_box "📁 Configuration Directory"
  show_new_line
  echo_blue "  Where to store your Good Morning configuration files"
  show_new_line
  echo_cyan "  Default: $DEFAULT_CONFIG_DIR"
  if [ -n "$current_config_dir" ]; then
    echo_cyan "  Current: $current_config_dir"
    echo_gray "  (Press Enter to keep current, or enter new path)"
  else
    echo_gray "  (Press Enter for default, or enter custom path)"
  fi
  show_new_line
  echo_green -n "  Config directory: "
  read -r config_dir_input

  if [ -n "$config_dir_input" ]; then
    config_dir_input="${config_dir_input/#\~/$HOME}"
    CONFIG_DIR="$config_dir_input"
    CONFIG_FILE="$CONFIG_DIR/config.sh"
  elif [ -n "$current_config_dir" ]; then
    CONFIG_DIR="$current_config_dir"
    CONFIG_FILE="$CONFIG_DIR/config.sh"
  fi

  mkdir -p "$CONFIG_DIR"

  # User name
  show_new_line
  section_box "👤 Your Name"
  show_new_line
  echo_blue "  Used for the personalized morning greeting banner"
  show_new_line
  echo_cyan "  Default: $USER"
  if [ -n "$current_user_name" ]; then
    echo_cyan "  Current: $current_user_name"
    echo_gray "  (Press Enter to keep current, or enter new name)"
  else
    echo_gray "  (Press Enter for default, or enter custom name)"
  fi
  show_new_line
  echo_green -n "  Your name: "
  read -r user_name_input

  if [ -n "$user_name_input" ]; then
    SETUP_USER_NAME="$user_name_input"
  elif [ -n "$current_user_name" ]; then
    SETUP_USER_NAME="$current_user_name"
  else
    SETUP_USER_NAME="$USER"
  fi

  # Text-to-speech
  show_new_line
  section_box "🔊 Text-to-Speech Greeting"
  show_new_line
  echo_blue "  Audibly announce 'Good morning' using macOS text-to-speech"
  show_new_line
  echo_cyan "  Default: disabled"
  if [ "$current_enable_tts" = "true" ]; then
    echo_cyan "  Current: enabled"
  fi
  echo_gray "  (y = enable, Enter/n = disable)"
  show_new_line
  echo_green -n "  Enable text-to-speech? [y/N]: "
  read -r enable_tts_input

  if [[ $enable_tts_input =~ ^[Yy]$ ]]; then
    SETUP_ENABLE_TTS="true"
  else
    SETUP_ENABLE_TTS="false"
  fi

  # Link behavior
  show_new_line
  section_box "🔗 Link Behavior"
  show_new_line
  echo_blue "  Automatically open links in browser?"
  echo_gray "  (Otherwise links are just displayed in terminal)"
  show_new_line
  echo_green -n "  Auto-open links? [y/N]: "
  read -r link_behavior_input

  if [[ $link_behavior_input =~ ^[Yy]$ ]]; then
    SETUP_AUTO_OPEN_LINKS="true"
  else
    SETUP_AUTO_OPEN_LINKS="false"
  fi

  print_success "Basic configuration complete ✅"
}

###############################################################################
# Section: Paths Configuration
###############################################################################
setup_section_paths() {
  print_header "📂 Paths Configuration"

  local current_backup_script=""
  local current_vim_plugins_dir=""
  local current_project_dirs=""

  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE" 2>/dev/null
    current_backup_script="${GOODMORNING_BACKUP_SCRIPT:-}"
    current_vim_plugins_dir="${GOODMORNING_VIM_PLUGINS_DIR:-}"
    current_project_dirs="${GOODMORNING_PROJECT_DIRS:-}"
  fi

  # Backup script
  show_new_line
  section_box "💾 Backup Script"
  show_new_line
  echo_blue "  Path to a script that runs backups (e.g., Time Machine, rsync)"
  echo_blue "  Will be executed in the background during your morning routine"
  show_new_line
  if [ -n "$current_backup_script" ]; then
    echo_cyan "  Current: $current_backup_script"
    echo_gray "  (Press Enter to keep current, or enter new path)"
  else
    echo_gray "  (Optional - press Enter to skip)"
  fi
  show_new_line
  echo_green -n "  Script path: "
  read -r backup_script_input

  if [ -n "$backup_script_input" ]; then
    SETUP_BACKUP_SCRIPT="$backup_script_input"
  else
    SETUP_BACKUP_SCRIPT="$current_backup_script"
  fi

  # Vim plugins directory
  show_new_line
  section_box "📝 Vim Plugins Directory"
  show_new_line
  echo_blue "  Directory containing your Vim plugins for automatic updates"
  show_new_line
  echo_cyan "  Default: \$HOME/.vim/pack/vendor/start"
  if [ -n "$current_vim_plugins_dir" ]; then
    echo_cyan "  Current: $current_vim_plugins_dir"
    echo_gray "  (Press Enter to keep current, or enter new path)"
  else
    echo_gray "  (Press Enter for default, or enter custom path)"
  fi
  show_new_line
  echo_green -n "  Directory: "
  read -r vim_plugins_input

  if [ -n "$vim_plugins_input" ]; then
    SETUP_VIM_PLUGINS_DIR="$vim_plugins_input"
  elif [ -n "$current_vim_plugins_dir" ]; then
    SETUP_VIM_PLUGINS_DIR="$current_vim_plugins_dir"
  else
    SETUP_VIM_PLUGINS_DIR="\$HOME/.vim/pack/vendor/start"
  fi

  # Project directories
  show_new_line
  section_box "📁 Project Directories"
  show_new_line
  echo_blue "  Directories to scan for git repositories"
  echo_blue "  Used to generate personalized learning tips from recent commits"
  echo_gray "  (Requires Claude Code CLI to be installed)"
  show_new_line
  echo_cyan "  Default: \$HOME"
  if [ -n "$current_project_dirs" ]; then
    echo_cyan "  Current: $current_project_dirs"
    echo_gray "  (Press Enter to keep current, or enter new paths)"
  else
    echo_gray "  (Press Enter for default, or enter custom paths)"
  fi
  echo_gray "  (Separate multiple paths with colons)"
  show_new_line
  echo_green -n "  Directories: "
  read -r project_dirs_input

  if [ -n "$project_dirs_input" ]; then
    SETUP_PROJECT_DIRS="$project_dirs_input"
  elif [ -n "$current_project_dirs" ]; then
    SETUP_PROJECT_DIRS="$current_project_dirs"
  else
    SETUP_PROJECT_DIRS="\$HOME"
  fi

  print_success "Paths configuration complete ✅"
}

###############################################################################
# Section: Learning Sources
###############################################################################
setup_section_learning() {
  print_header "📚 Learning Sources Configuration"

  show_new_line
  echo_gray "  Example output:"
  echo_gray "    📚 Learning Resources:"
  echo_gray "    • PostgreSQL: Window Functions"
  echo_gray "      https://postgresql.org/docs/..."
  show_new_line
  echo_gray "  (Enter/y = enable, n = disable)"
  show_new_line
  echo_green -n "  Enable? [Y/n]: "
  read -r response
  if [[ -z "$response" || "$response" =~ ^[Yy]$ ]]; then
    SETUP_SHOW_LEARNING="true"
  else
    SETUP_SHOW_LEARNING="false"
    print_info "Learning resources disabled"
    return
  fi

  show_new_line
  echo_blue "  Daily Learning shows two random documentation resources:"
  show_new_line
  echo_cyan "  📄 Sitemaps: Fetches a random page from site's sitemap"
  echo_gray "     Best for: Large documentation sites with changing content"
  echo_gray "     Example: PostgreSQL, Docker, Kubernetes docs"
  show_new_line
  echo_cyan "  🔗 Static: Direct links to specific documentation pages"
  echo_gray "     Best for: Sites without sitemaps or your favorite references"
  echo_gray "     Example: AWS guides, Linux man pages, language docs"
  show_new_line

  local json_file="$CONFIG_DIR/learning-sources.json"
  mkdir -p "$CONFIG_DIR"

  # Check for existing config
  if [ -f "$json_file" ]; then
    local sitemap_count=$(jq '.sitemaps | length' "$json_file" 2>/dev/null || echo "0")
    local static_count=$(jq '.static | length' "$json_file" 2>/dev/null || echo "0")
    echo_cyan "  Current: $sitemap_count sitemaps, $static_count static links"
    show_new_line
  fi

  show_new_line
  echo_blue "  Use the curated default sources? Includes:"
  echo_gray "    💻 Programming: PostgreSQL, Ruby, Node.js, Python, Go, Rust"
  echo_gray "    🤖 AI/ML: OpenAI, Anthropic, PyTorch, TensorFlow"
  echo_gray "    🐳 DevOps: Docker, Kubernetes, Git, Nginx, Grafana"
  echo_gray "    🔒 Security: OWASP, CVE Database, PortSwigger"
  echo_gray "    🛠️  Tools: VS Code, JetBrains, Vim, Zsh"
  show_new_line
  echo_gray "  (Enter/y = use defaults, n = start empty and add your own)"
  show_new_line
  echo_green -n "  Use default sources? [Y/n]: "
  read -r use_defaults

  if [[ ! $use_defaults =~ ^[Nn]$ ]]; then
    # Copy default sources
    cp "$SCRIPT_DIR/data/learning-sources.json" "$json_file"
    print_success "Default learning sources installed"
  else
    # Start with empty structure
    echo '{"sitemaps": [], "static": []}' > "$json_file"
    print_info "Starting with empty sources"

    # Only prompt for custom URLs if user rejected defaults
    show_new_line
    section_box "➕ Add Custom Documentation Links"
    show_new_line
    echo_blue "  Add your own documentation URLs (space-separated)"
    echo_gray "  These will be added to the static resources list"
    echo_gray "  Example: https://docs.example.com https://wiki.mycompany.com"
    show_new_line
    echo_gray "  (Enter = skip, or enter URLs separated by spaces)"
    show_new_line
    echo_green -n "  Custom URLs: "
    read -r custom_urls

    if [ -n "$custom_urls" ]; then
      for url in ${=custom_urls}; do
        if [[ "$url" =~ ^https?:// ]]; then
          # Extract title from URL
          local title=$(echo "$url" | sed -E 's|https?://([^/]+).*|\1|' | sed 's/^www\.//' | sed 's/\..*//' | awk '{print toupper(substr($0,1,1)) substr($0,2)}')

          # Add to JSON
          local tmp_file=$(mktemp)
          jq --arg title "$title" --arg url "$url" \
            '.static += [{"title": $title, "url": $url}]' \
            "$json_file" > "$tmp_file" && mv "$tmp_file" "$json_file"

          print_success "Added: $title ($url)"
        else
          print_warning "Skipped invalid URL: $url"
        fi
      done
    fi
  fi

  # Show summary
  show_new_line
  local final_sitemap_count=$(jq '.sitemaps | length' "$json_file" 2>/dev/null || echo "0")
  local final_static_count=$(jq '.static | length' "$json_file" 2>/dev/null || echo "0")
  print_success "Learning sources configured: $final_sitemap_count sitemaps, $final_static_count static ✅"
  print_info "📝 Edit directly: $json_file"
}

###############################################################################
# Section: Banner
###############################################################################
setup_section_banner() {
  print_header "🎨 ASCII Art Banner"

  if [ -z "${SETUP_USER_NAME:-}" ]; then
    if [ -f "$CONFIG_FILE" ]; then
      source "$CONFIG_FILE" 2>/dev/null
      SETUP_USER_NAME="${GOODMORNING_USER_NAME:-$USER}"
    else
      SETUP_USER_NAME="$USER"
    fi
  fi

  # Check if figlet is available
  if ! command -v figlet &> /dev/null; then
    show_new_line
    print_info "Skipping (figlet not installed)"
    echo_gray "  Install with: brew install figlet"
    return 0
  fi

  show_new_line
  echo_blue "  Show a personalized \"GOOD MORNING $SETUP_USER_NAME\" banner?"
  show_new_line
  echo_green -n "  Create ASCII banner? [Y/n]: "
  read -r generate_banner

  local banner_file="$CONFIG_DIR/banner.txt"

  if [[ ! $generate_banner =~ ^[Nn]$ ]]; then
    {
      figlet -f standard "GOOD MORNING" 2>/dev/null || figlet "GOOD MORNING"
      show_new_line
      figlet -f standard "${SETUP_USER_NAME}" 2>/dev/null || figlet "${SETUP_USER_NAME}"
    } > "$banner_file"
    print_success "Banner created"
    print_info "📝 Edit: $banner_file"
  else
    print_info "Using default banner"
  fi
}

###############################################################################
# Section: Briefing Features
###############################################################################
setup_section_features() {
  print_header "✨ Briefing Features"

  show_new_line
  echo_blue "  Choose which sections to include in your morning briefing."
  echo_blue "  Each feature can be individually enabled or disabled."
  show_new_line

  # Helper function to ask about a feature
  ask_feature() {
    local var_name="$1"
    local description="$2"
    local default="${3:-true}"
    local extra_prompt="$4"

    local default_display="Y/n"
    local hint="(Enter/y = enable, n = disable)"
    if [[ "$default" != "true" ]]; then
      default_display="y/N"
      hint="(y = enable, Enter/n = disable)"
    fi

    section_box "$description"
    echo_gray "  $hint"
    show_new_line
    echo_green -n "  Enable? [$default_display]: "
    read -r response

    if [[ -z "$response" ]]; then
      eval "SETUP_$var_name=\"$default\""
    elif [[ $response =~ ^[Yy]$ ]]; then
      eval "SETUP_$var_name=\"true\""
    else
      eval "SETUP_$var_name=\"false\""
    fi

    # Handle extra prompts for specific features
    if [[ -n "$extra_prompt" ]] && [[ "$(eval echo \$SETUP_$var_name)" == "true" ]]; then
      eval "$extra_prompt"
    fi
  }

  # Ask about each feature with examples

  show_new_line
  section_box "🌤️ Weather Forecast"
  show_new_line
  echo_gray "  Example output:"
  echo_gray "    ☀️  Weather: 72°F, Sunny"
  echo_gray "    High: 78°F  Low: 65°F"
  show_new_line
  echo_gray "  (Enter/y = enable, n = disable)"
  show_new_line
  echo_green -n "  Enable? [Y/n]: "
  read -r response
  [[ -z "$response" || "$response" =~ ^[Yy]$ ]] && SETUP_SHOW_WEATHER="true" || SETUP_SHOW_WEATHER="false"

  if [[ "$SETUP_SHOW_WEATHER" == "true" ]]; then
    show_new_line
    echo_gray "  Weather requires a location (IP geolocation is unreliable)."
    echo_gray "  Use underscores for spaces (e.g., san_francisco, new_york)"
    show_new_line
    echo_green -n "  Your city: "
    read -r location_input
    # Lowercase the location for wttr.in compatibility
    SETUP_WEATHER_LOCATION="${location_input:l}"
  fi

  show_new_line
  section_box "📜 On This Day in History"
  show_new_line
  echo_gray "  Example output:"
  echo_gray "    📅 On This Day (November 19):"
  echo_gray "    • 1863: Lincoln delivers Gettysburg Address"
  echo_gray "    • 1969: Apollo 12 lands on the Moon"
  show_new_line
  echo_gray "  (Enter/y = enable, n = disable)"
  show_new_line
  echo_green -n "  Enable? [Y/n]: "
  read -r response
  [[ -z "$response" || "$response" =~ ^[Yy]$ ]] && SETUP_SHOW_HISTORY="true" || SETUP_SHOW_HISTORY="false"

  show_new_line
  section_box "💻 Latest Tech Versions"
  show_new_line
  echo_gray "  Example output:"
  echo_gray "    🔧 Latest Versions:"
  echo_gray "    Ruby         v3.4.1          Rails        v8.0.1"
  echo_gray "    TypeScript   v5.7.2          Node.js      v23.4.0"
  echo_gray "    Go           1.23.4          Python       3.13.1"
  show_new_line
  echo_gray "  (Enter/y = enable, n = disable)"
  show_new_line
  echo_green -n "  Enable? [Y/n]: "
  read -r response
  [[ -z "$response" || "$response" =~ ^[Yy]$ ]] && SETUP_SHOW_TECH_VERSIONS="true" || SETUP_SHOW_TECH_VERSIONS="false"

  show_new_line
  section_box "🌍 Country of the Day"
  show_new_line
  echo_gray "  Example output:"
  echo_gray "    🌍 Country: Japan"
  echo_gray "    Capital: Tokyo | Population: 125M"
  echo_gray "    Notable: Has over 6,800 islands"
  show_new_line
  echo_gray "  (Enter/y = enable, n = disable)"
  show_new_line
  echo_green -n "  Enable? [Y/n]: "
  read -r response
  [[ -z "$response" || "$response" =~ ^[Yy]$ ]] && SETUP_SHOW_COUNTRY="true" || SETUP_SHOW_COUNTRY="false"

  show_new_line
  section_box "📚 Word of the Day"
  show_new_line
  echo_gray "  Example output:"
  echo_gray "    📖 Word: Ephemeral (adj.)"
  echo_gray "    Lasting for a very short time"
  show_new_line
  echo_gray "  (Enter/y = enable, n = disable)"
  show_new_line
  echo_green -n "  Enable? [Y/n]: "
  read -r response
  [[ -z "$response" || "$response" =~ ^[Yy]$ ]] && SETUP_SHOW_WORD="true" || SETUP_SHOW_WORD="false"

  show_new_line
  section_box "📖 Wikipedia Featured Article"
  show_new_line
  echo_gray "  Example output:"
  echo_gray "    📚 Wikipedia: \"Golden Gate Bridge\""
  echo_gray "    A suspension bridge spanning the Golden Gate strait..."
  show_new_line
  echo_gray "  (Enter/y = enable, n = disable)"
  show_new_line
  echo_green -n "  Enable? [Y/n]: "
  read -r response
  [[ -z "$response" || "$response" =~ ^[Yy]$ ]] && SETUP_SHOW_WIKIPEDIA="true" || SETUP_SHOW_WIKIPEDIA="false"

  show_new_line
  section_box "🔭 NASA Astronomy Picture"
  show_new_line
  echo_gray "  Example output:"
  echo_gray "    🔭 APOD: \"Orion Nebula in Infrared\""
  echo_gray "    https://apod.nasa.gov/apod/image/..."
  show_new_line
  echo_gray "  (Enter/y = enable, n = disable)"
  show_new_line
  echo_green -n "  Enable? [Y/n]: "
  read -r response
  if [[ -z "$response" || "$response" =~ ^[Yy]$ ]]; then
    SETUP_SHOW_APOD="true"

    # Check for existing NASA API key
    local current_nasa_key=""
    if [ -f "$CONFIG_FILE" ]; then
      source "$CONFIG_FILE" 2>/dev/null
      current_nasa_key="${GOODMORNING_NASA_API_KEY:-}"
    fi

    show_new_line
    if [ -n "$current_nasa_key" ] && [ "$current_nasa_key" != "DEMO_KEY" ]; then
      local masked_key="${current_nasa_key:0:8}...${current_nasa_key: -4}"
      echo_cyan "  Current NASA API key: $masked_key"
      echo_gray "  (Press Enter to keep current, 'demo' for DEMO_KEY, or paste new key)"
      show_new_line
      echo_green -n "  NASA API key: "
      read -r nasa_key_input
      if [ -z "$nasa_key_input" ]; then
        SETUP_NASA_API_KEY="$current_nasa_key"
        print_success "Keeping existing NASA API key 🚀"
      elif [ "$nasa_key_input" = "demo" ]; then
        SETUP_NASA_API_KEY=""
        print_warning "Switched to DEMO_KEY (rate limited)"
      else
        SETUP_NASA_API_KEY="$nasa_key_input"
        print_success "NASA API key updated! 🚀"
      fi
    else
      echo_yellow "  ⚠️  NASA API Rate Limits"
      show_new_line
      echo_blue "  The default DEMO_KEY has strict rate limits (30 requests/hour per IP)"
      echo_blue "  and may not work reliably. Get a free personal API key for better reliability:"
      show_new_line
      echo_cyan "  🔗 Get your free NASA API key:"
      echo_green "     https://api.nasa.gov"
      show_new_line
      echo_gray "  (Enter = use DEMO_KEY, or paste your API key)"
      show_new_line
      echo_green -n "  NASA API key: "
      read -r SETUP_NASA_API_KEY
      if [ -n "$SETUP_NASA_API_KEY" ]; then
        print_success "NASA API key configured! 🚀"
      else
        print_warning "Using DEMO_KEY (rate limited)"
      fi
    fi
  else
    SETUP_SHOW_APOD="false"
  fi

  show_new_line
  section_box "📅 Calendar Events"
  show_new_line
  echo_gray "  Example output:"
  echo_gray "    📆 Today's Events:"
  echo_gray "    • 9:00 AM - Team standup"
  echo_gray "    • 2:00 PM - Project review"
  show_new_line
  echo_gray "  (Enter/y = enable, n = disable)"
  show_new_line
  echo_green -n "  Enable? [Y/n]: "
  read -r response
  [[ -z "$response" || "$response" =~ ^[Yy]$ ]] && SETUP_SHOW_CALENDAR="true" || SETUP_SHOW_CALENDAR="false"

  show_new_line
  section_box "✅ macOS Reminders"
  show_new_line
  echo_gray "  Example output:"
  echo_gray "    ✅ Reminders:"
  echo_gray "    • Buy groceries"
  echo_gray "    • Call dentist"
  show_new_line
  echo_gray "  (Enter/y = enable, n = disable)"
  show_new_line
  echo_green -n "  Enable? [Y/n]: "
  read -r response
  if [[ -z "$response" || "$response" =~ ^[Yy]$ ]]; then
    SETUP_SHOW_REMINDERS="true"
    show_new_line
    echo_blue "  Which reminder list should be displayed?"
    show_new_line
    echo_gray "  (Enter = show all incomplete reminders, or enter specific list name)"
    show_new_line
    echo_green -n "  Reminder list name: "
    read -r SETUP_REMINDERS_LIST
  else
    SETUP_SHOW_REMINDERS="false"
  fi

  show_new_line
  section_box "🐙 GitHub Notifications"
  show_new_line
  echo_gray "  Example output:"
  echo_gray "    🐙 GitHub: 3 unread notifications"
  echo_gray "    • PR review requested: feature-branch"
  show_new_line
  echo_gray "  (Enter/y = enable, n = disable)"
  show_new_line
  echo_green -n "  Enable? [Y/n]: "
  read -r response
  if [[ -z "$response" || "$response" =~ ^[Yy]$ ]]; then
    SETUP_SHOW_GITHUB="true"
    if ! command -v gh &> /dev/null; then
      print_warning "GitHub CLI (gh) is not installed"
      echo_cyan "  Install with: brew install gh"
      show_new_line
      echo_gray "  (y = enable anyway, Enter/n = disable)"
      show_new_line
      echo_green -n "  Continue anyway? [y/N]: "
      read -r continue_anyway
      if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
        SETUP_SHOW_GITHUB="false"
        print_info "GitHub notifications disabled"
      fi
    elif ! gh auth status &>/dev/null; then
      print_warning "GitHub CLI is not authenticated"
      echo_cyan "  Run: gh auth login"
      show_new_line
      echo_gray "  (y = enable anyway, Enter/n = disable)"
      show_new_line
      echo_green -n "  Continue anyway? [y/N]: "
      read -r continue_anyway
      if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
        SETUP_SHOW_GITHUB="false"
        print_info "GitHub notifications disabled"
      fi
    else
      print_success "GitHub CLI installed and authenticated"
    fi
  else
    SETUP_SHOW_GITHUB="false"
  fi

  show_new_line
  section_box "🤪 Sanity Maintenance"
  show_new_line
  echo_gray "  Example output:"
  echo_gray "    😄 Sanity Break:"
  echo_gray "    • XKCD: \"Standards\""
  echo_gray "      https://xkcd.com/927/"
  show_new_line
  echo_gray "  (Enter/y = enable, n = disable)"
  show_new_line
  echo_green -n "  Enable? [Y/n]: "
  read -r response
  [[ -z "$response" || "$response" =~ ^[Yy]$ ]] && SETUP_SHOW_SANITY="true" || SETUP_SHOW_SANITY="false"

  show_new_line
  section_box "🤖 AI Learning Tips"
  show_new_line
  echo_gray "  Example output:"
  echo_gray "    🤖 Learning Tip:"
  echo_gray "    Use git stash to temporarily save changes"
  echo_gray "    without committing them..."
  echo_gray "    Source: Git Documentation"
  show_new_line
  echo_gray "  (Requires Claude Code CLI)"
  echo_gray "  (Enter/y = enable, n = disable)"
  show_new_line
  echo_green -n "  Enable? [Y/n]: "
  read -r response
  [[ -z "$response" || "$response" =~ ^[Yy]$ ]] && SETUP_SHOW_TIPS="true" || SETUP_SHOW_TIPS="false"

  show_new_line
  section_box "🔄 Background System Updates"
  show_new_line
  echo_gray "  Example output:"
  echo_gray "    🔄 Running background updates..."
  echo_gray "    • Homebrew formulae (nvim, git, etc.)"
  echo_gray "    • Homebrew casks (Chrome, Firefox, etc.)"
  echo_gray "    • Claude Code CLI"
  echo_gray "    Notification when complete"
  show_new_line
  echo_gray "  (Enter/y = enable, n = disable)"
  show_new_line
  echo_green -n "  Enable? [Y/n]: "
  read -r response
  [[ -z "$response" || "$response" =~ ^[Yy]$ ]] && SETUP_RUN_UPDATES="true" || SETUP_RUN_UPDATES="false"

  print_success "Briefing features configured ✅"
}

###############################################################################
# Section: Installation
###############################################################################
setup_section_install() {
  print_header "🚀 Installation"

  mkdir -p "$INSTALL_DIR"
  mkdir -p "$CONFIG_DIR"

  # Write config file
  cat > "$CONFIG_FILE" << EOF
# Good Morning Script Configuration
# Generated by setup.sh

export GOODMORNING_CONFIG_DIR="${CONFIG_DIR}"
export GOODMORNING_USER_NAME="${SETUP_USER_NAME:-\$USER}"
export GOODMORNING_ENABLE_TTS="${SETUP_ENABLE_TTS:-false}"
export GOODMORNING_OPEN_LINKS="${SETUP_AUTO_OPEN_LINKS:-false}"
export GOODMORNING_BACKUP_SCRIPT="${SETUP_BACKUP_SCRIPT:-}"
export GOODMORNING_VIM_PLUGINS_DIR="${SETUP_VIM_PLUGINS_DIR:-\$HOME/.vim/pack/vendor/start}"
export GOODMORNING_PROJECT_DIRS="${SETUP_PROJECT_DIRS:-\$HOME}"
export GOODMORNING_LOGS_DIR="${CONFIG_DIR}/logs"
export GOODMORNING_OUTPUT_HISTORY_DIR="${CONFIG_DIR}/output_history"

# API Keys
EOF

  # Add NASA API key if provided
  if [ -n "$SETUP_NASA_API_KEY" ]; then
    cat >> "$CONFIG_FILE" << EOF
export GOODMORNING_NASA_API_KEY="${SETUP_NASA_API_KEY}"
EOF
  fi

  cat >> "$CONFIG_FILE" << EOF

# Briefing feature flags
export GOODMORNING_SHOW_SETUP_MESSAGES="${SETUP_SHOW_SETUP_MESSAGES:-true}"
export GOODMORNING_SHOW_WEATHER="${SETUP_SHOW_WEATHER:-true}"
export GOODMORNING_WEATHER_LOCATION="${SETUP_WEATHER_LOCATION:-}"
export GOODMORNING_SHOW_HISTORY="${SETUP_SHOW_HISTORY:-true}"
export GOODMORNING_SHOW_TECH_VERSIONS="${SETUP_SHOW_TECH_VERSIONS:-true}"
export GOODMORNING_SHOW_SYSTEM_INFO="${SETUP_SHOW_SYSTEM_INFO:-true}"
export GOODMORNING_SHOW_COUNTRY="${SETUP_SHOW_COUNTRY:-true}"
export GOODMORNING_SHOW_WORD="${SETUP_SHOW_WORD:-true}"
export GOODMORNING_SHOW_WIKIPEDIA="${SETUP_SHOW_WIKIPEDIA:-true}"
export GOODMORNING_SHOW_APOD="${SETUP_SHOW_APOD:-true}"
export GOODMORNING_SHOW_CAT="${SETUP_SHOW_CAT:-true}"
export GOODMORNING_SHOW_CALENDAR="${SETUP_SHOW_CALENDAR:-true}"
export GOODMORNING_SHOW_REMINDERS="${SETUP_SHOW_REMINDERS:-true}"
export GOODMORNING_REMINDERS_LIST="${SETUP_REMINDERS_LIST:-}"
export GOODMORNING_SHOW_GITHUB="${SETUP_SHOW_GITHUB:-true}"
export GOODMORNING_SHOW_GITHUB_PRS="${SETUP_SHOW_GITHUB_PRS:-true}"
export GOODMORNING_SHOW_GITHUB_ISSUES="${SETUP_SHOW_GITHUB_ISSUES:-true}"
export GOODMORNING_SHOW_LEARNING="${SETUP_SHOW_LEARNING:-true}"
export GOODMORNING_SHOW_SANITY="${SETUP_SHOW_SANITY:-true}"
export GOODMORNING_SHOW_TIPS="${SETUP_SHOW_TIPS:-true}"
export GOODMORNING_SHOW_ALIAS_SUGGESTIONS="${SETUP_SHOW_ALIAS_SUGGESTIONS:-true}"
export GOODMORNING_RUN_UPDATES="${SETUP_RUN_UPDATES:-true}"

# Setup completion marker (used by preflight checks)
export GOODMORNING_SETUP_COMPLETE="true"
EOF

  print_success "Configuration saved to $CONFIG_FILE 💾"

  # Create symlinks
  print_info "🔗 Creating symlinks in $INSTALL_DIR..."

  for file in goodmorning.sh setup.sh; do
    local source_file="$SCRIPT_DIR/$file"
    local target_link="$INSTALL_DIR/$file"

    if [ -f "$source_file" ]; then
      if [ -L "$target_link" ]; then
        rm "$target_link"
      elif [ -e "$target_link" ]; then
        mv "$target_link" "${target_link}.backup"
        print_warning "Existing file backed up: ${target_link}.backup"
      fi

      ln -s "$source_file" "$target_link"
      print_success "Symlinked $file ✓"
    fi
  done

  print_header "🎉 Setup Complete!"

  show_new_line
  echo_cyan "Add to your shell config (~/.zshrc):"
  echo_green "  echo 'source $CONFIG_FILE' >> ~/.zshrc"
  show_new_line
  echo_gray "  Optional alias: alias gm=\"$INSTALL_DIR/goodmorning.sh\""
  show_new_line
  echo_cyan "Run now with: $(echo_green './goodmorning.sh')"
  show_new_line
}

###############################################################################
# Main Setup Functions
###############################################################################
run_interactive_setup() {
  setup_section_system
  setup_section_basic
  setup_section_paths
  setup_section_features
  setup_section_learning
  setup_section_banner
  setup_section_install
}

run_section() {
  local section="$1"

  case "$section" in
    system)
      setup_section_system
      ;;
    basic)
      setup_section_basic
      setup_section_install
      ;;
    paths)
      setup_section_paths
      setup_section_install
      ;;
    features)
      setup_section_features
      setup_section_install
      ;;
    learning)
      setup_section_learning
      ;;
    banner)
      setup_section_banner
      ;;
    install)
      setup_section_install
      ;;
    *)
      print_error "Unknown section: $section"
      show_new_line
      echo_cyan "Available sections:"
      echo "  system   - Check system requirements"
      echo "  basic    - User name, TTS, config directory"
      echo "  paths    - Backup script, vim plugins, project dirs"
      echo "  features - Enable/disable briefing sections"
      echo "  learning - Learning sources configuration"
      echo "  banner   - ASCII art banner generation"
      echo "  install  - Write config and create symlinks"
      exit 1
      ;;
  esac
}

show_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    print_error "No configuration file found at $CONFIG_FILE"
    show_new_line
    echo "Run $(echo_green './setup.sh') to create a configuration."
    exit 1
  fi

  print_header "📋 Current Configuration"
  show_new_line

  source "$CONFIG_FILE"

  echo_cyan "📁 Configuration file: $CONFIG_FILE"
  show_new_line

  echo_yellow "👤 User Name:"
  echo "  ${GOODMORNING_USER_NAME:-\$USER}"
  show_new_line

  echo_yellow "🔊 Text-to-Speech:"
  echo "  ${GOODMORNING_ENABLE_TTS:-false}"
  show_new_line

  echo_yellow "💾 Backup Script:"
  if [ -n "$GOODMORNING_BACKUP_SCRIPT" ]; then
    echo "  $GOODMORNING_BACKUP_SCRIPT"
  else
    echo_gray "  (not configured)"
  fi
  show_new_line

  echo_yellow "📚 Learning Sources:"
  local json_file="${GOODMORNING_CONFIG_DIR:-$CONFIG_DIR}/learning-sources.json"
  if [ -f "$json_file" ]; then
    local sitemap_count=$(jq '.sitemaps | length' "$json_file" 2>/dev/null || echo "0")
    local static_count=$(jq '.static | length' "$json_file" 2>/dev/null || echo "0")
    echo "  $json_file"
    echo_blue "  Sitemaps: $sitemap_count, Static: $static_count"
  else
    echo_gray "  (not configured)"
  fi
  show_new_line
}

show_usage() {
  echo_cyan "☀️  Good Morning Script Setup"
  show_new_line
  echo_yellow "📋 Usage:"
  echo "  ./setup.sh                    Run full interactive setup"
  echo "  ./setup.sh --section <name>   Configure only one section"
  echo "  ./setup.sh --reconfigure      Force re-running full setup"
  echo "  ./setup.sh --show-config      Display current configuration"
  echo "  ./setup.sh --help             Show this help message"
  show_new_line
  echo_yellow "📦 Sections:"
  echo "  system   - 🔍 Check system requirements and dependencies"
  echo "  basic    - ⚙️  User name, TTS, config directory"
  echo "  paths    - 📂 Backup script, vim plugins, project directories"
  echo "  learning - 📚 Learning sources (sitemaps and static URLs)"
  echo "  banner   - 🎨 ASCII art banner generation"
  echo "  install  - 🚀 Write config file and create symlinks"
  show_new_line
  echo_yellow "💡 Examples:"
  echo_green "  ./setup.sh --section learning"
  echo "    Configure only learning sources"
  show_new_line
  echo_green "  ./setup.sh --section banner"
  echo "    Regenerate ASCII art banner"
  show_new_line
  echo_yellow "Configuration:"
  echo "  Config directory: $(echo_cyan "$CONFIG_DIR")"
  echo "  Config file:      $(echo_cyan "$CONFIG_FILE")"
  show_new_line
}

# Parse command line arguments
case "$1" in
  --help|-h)
    show_usage
    ;;
  --show-config)
    show_config
    ;;
  --check-system)
    setup_section_system false
    ;;
  --reconfigure)
    run_interactive_setup
    ;;
  --regenerate-banner)
    setup_section_banner
    ;;
  --section)
    if [ -z "$2" ]; then
      print_error "Section name required"
      show_new_line
      echo_cyan "Available sections: system, basic, paths, learning, banner, install"
      exit 1
    fi
    run_section "$2"
    ;;
  "")
    run_interactive_setup
    ;;
  *)
    print_error "Unknown option: $1"
    show_new_line
    show_usage
    exit 1
    ;;
esac
