#!/usr/bin/env zsh

set -e

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
DEFAULT_INSTALL_DIR="$HOME/.config/zsh/scripts"
DEFAULT_CONFIG_DIR="$HOME/.config/goodmorning"
INSTALL_DIR="${GOODMORNING_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
CONFIG_DIR="${GOODMORNING_CONFIG_DIR:-$DEFAULT_CONFIG_DIR}"
CONFIG_FILE="$CONFIG_DIR/config.sh"

# Source centralized color functions
source "$SCRIPT_DIR/lib/colors.sh"

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
  echo_yellow "⚠ $1"
}

print_header() {
  echo ""
  echo_cyan "========================================"
  echo_cyan "  $1"
  echo_cyan "========================================"
}

###############################################################################
# Section: System Requirements
###############################################################################
setup_section_system() {
  local interactive="${1:-true}"

  print_header "System Requirements Check"

  if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script requires macOS"
    echo_yellow "Current OS: $OSTYPE"
    exit 1
  fi
  print_success "Running on macOS"

  local missing_required=()
  local missing_optional=()

  echo ""
  echo_cyan "Checking required dependencies..."

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

  echo ""
  echo_cyan "Checking optional dependencies..."

  if ! command -v brew &> /dev/null; then
    missing_optional+=("brew")
    print_warning "Homebrew not found (recommended for updates)"
  else
    print_success "Homebrew found"
  fi

  if ! command -v figlet &> /dev/null; then
    missing_optional+=("figlet")
    print_warning "figlet not found (needed for custom banners)"
  else
    print_success "figlet found"
  fi

  if ! command -v icalBuddy &> /dev/null; then
    missing_optional+=("icalBuddy")
    print_warning "icalBuddy not found (needed for calendar/reminders)"
  else
    print_success "icalBuddy found"
  fi

  if ! command -v claude &> /dev/null; then
    missing_optional+=("claude")
    print_warning "Claude Code not found (needed for learning tips)"
  else
    print_success "Claude Code found"
  fi

  if [ ${#missing_required[@]} -gt 0 ]; then
    echo ""
    echo_red "Missing required dependencies:"
    for dep in "${missing_required[@]}"; do
      echo "  - $dep"
    done
    if command -v brew &> /dev/null; then
      echo ""
      echo_cyan "Install with:"
      for dep in "${missing_required[@]}"; do
        echo_green "  brew install $dep"
      done
    fi
    exit 1
  fi

  if [ ${#missing_optional[@]} -gt 0 ] && [ "$interactive" = "true" ]; then
    echo ""
    echo_yellow "Missing optional dependencies:"
    for dep in "${missing_optional[@]}"; do
      echo "  - $dep"
    done

    if command -v brew &> /dev/null; then
      echo ""
      echo_cyan "Install missing optional dependencies with Homebrew?"
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
          esac
        done
      fi
    fi
  fi

  echo ""
}

###############################################################################
# Section: Basic Configuration
###############################################################################
setup_section_basic() {
  print_header "Basic Configuration"

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
  echo ""
  echo_yellow "━━━ Configuration Directory ━━━"
  echo ""
  echo_blue "  Where to store your Good Morning configuration files"
  echo ""
  echo_cyan "  Default: $DEFAULT_CONFIG_DIR"
  if [ -n "$current_config_dir" ]; then
    echo_cyan "  Current: $current_config_dir"
  fi
  echo ""
  echo_green -n "  Your choice (Enter for default): "
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
  echo ""
  echo_yellow "━━━ Your Name ━━━"
  echo ""
  echo_blue "  Used for the personalized morning greeting banner"
  echo ""
  echo_cyan "  Default: $USER"
  if [ -n "$current_user_name" ]; then
    echo_cyan "  Current: $current_user_name"
  fi
  echo ""
  echo_green -n "  Your choice: "
  read -r user_name_input

  if [ -n "$user_name_input" ]; then
    SETUP_USER_NAME="$user_name_input"
  elif [ -n "$current_user_name" ]; then
    SETUP_USER_NAME="$current_user_name"
  else
    SETUP_USER_NAME="$USER"
  fi

  # Text-to-speech
  echo ""
  echo_yellow "━━━ Text-to-Speech Greeting ━━━"
  echo ""
  echo_blue "  Audibly announce 'Good morning' using macOS text-to-speech"
  echo ""
  echo_cyan "  Default: disabled"
  if [ "$current_enable_tts" = "true" ]; then
    echo_cyan "  Current: enabled"
  fi
  echo ""
  echo_green -n "  Enable text-to-speech? [y/N]: "
  read -r enable_tts_input

  if [[ $enable_tts_input =~ ^[Yy]$ ]]; then
    SETUP_ENABLE_TTS="true"
  else
    SETUP_ENABLE_TTS="false"
  fi

  print_success "Basic configuration complete"
}

###############################################################################
# Section: Paths Configuration
###############################################################################
setup_section_paths() {
  print_header "Paths Configuration"

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
  echo ""
  echo_yellow "━━━ Backup Script ━━━"
  echo ""
  echo_blue "  Path to a script that runs backups (e.g., Time Machine, rsync)"
  echo_blue "  Will be executed in the background during your morning routine"
  echo ""
  if [ -n "$current_backup_script" ]; then
    echo_cyan "  Current: $current_backup_script"
  fi
  echo_gray "  (Optional - press Enter to skip)"
  echo ""
  echo_green -n "  Script path: "
  read -r backup_script_input

  if [ -n "$backup_script_input" ]; then
    SETUP_BACKUP_SCRIPT="$backup_script_input"
  else
    SETUP_BACKUP_SCRIPT="$current_backup_script"
  fi

  # Vim plugins directory
  echo ""
  echo_yellow "━━━ Vim Plugins Directory ━━━"
  echo ""
  echo_blue "  Directory containing your Vim plugins for automatic updates"
  echo ""
  echo_cyan "  Default: \$HOME/.vim/pack/vendor/start"
  if [ -n "$current_vim_plugins_dir" ]; then
    echo_cyan "  Current: $current_vim_plugins_dir"
  fi
  echo ""
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
  echo ""
  echo_yellow "━━━ Project Directories ━━━"
  echo ""
  echo_blue "  Directories to scan for git repositories"
  echo_blue "  Used to check for uncommitted changes across your projects"
  echo ""
  echo_cyan "  Default: \$HOME"
  if [ -n "$current_project_dirs" ]; then
    echo_cyan "  Current: $current_project_dirs"
  fi
  echo_gray "  (Separate multiple paths with colons)"
  echo ""
  echo_green -n "  Directories: "
  read -r project_dirs_input

  if [ -n "$project_dirs_input" ]; then
    SETUP_PROJECT_DIRS="$project_dirs_input"
  elif [ -n "$current_project_dirs" ]; then
    SETUP_PROJECT_DIRS="$current_project_dirs"
  else
    SETUP_PROJECT_DIRS="\$HOME"
  fi

  print_success "Paths configuration complete"
}

###############################################################################
# Section: Learning Sources
###############################################################################
setup_section_learning() {
  print_header "Learning Sources Configuration"

  echo ""
  echo_blue "  Daily Learning shows two random documentation resources:"
  echo ""
  echo_cyan "  📄 Sitemaps: Fetches a random page from site's sitemap"
  echo_gray "     Best for: Large documentation sites with changing content"
  echo_gray "     Example: PostgreSQL, Docker, Kubernetes docs"
  echo ""
  echo_cyan "  🔗 Static: Direct links to specific documentation pages"
  echo_gray "     Best for: Sites without sitemaps or your favorite references"
  echo_gray "     Example: AWS guides, Linux man pages, language docs"
  echo ""

  local json_file="$CONFIG_DIR/learning-sources.json"
  mkdir -p "$CONFIG_DIR"

  # Check for existing config
  if [ -f "$json_file" ]; then
    local sitemap_count=$(jq '.sitemaps | length' "$json_file" 2>/dev/null || echo "0")
    local static_count=$(jq '.static | length' "$json_file" 2>/dev/null || echo "0")
    echo_cyan "  Current: $sitemap_count sitemaps, $static_count static links"
    echo ""
  fi

  echo_yellow "━━━ Default Sources ━━━"
  echo ""
  echo_blue "  Use the curated default sources? Includes:"
  echo_gray "    • Programming: PostgreSQL, Ruby, Node.js, Python, Go, Rust"
  echo_gray "    • AI/ML: OpenAI, Anthropic, PyTorch, TensorFlow"
  echo_gray "    • DevOps: Docker, Kubernetes, Git, Nginx, Grafana"
  echo_gray "    • Security: OWASP, CVE Database, PortSwigger"
  echo_gray "    • Tools: VS Code, JetBrains, Vim, Zsh"
  echo ""
  echo_green -n "  Use default sources? [Y/n]: "
  read -r use_defaults

  if [[ ! $use_defaults =~ ^[Nn]$ ]]; then
    # Copy default sources
    cp "$SCRIPT_DIR/learning-sources.json" "$json_file"
    print_success "Default learning sources installed"
  else
    # Start with empty structure
    echo '{"sitemaps": [], "static": []}' > "$json_file"
    print_info "Starting with empty sources"
  fi

  # Add custom static URLs
  echo ""
  echo_yellow "━━━ Add Custom Documentation Links ━━━"
  echo ""
  echo_blue "  Add your own documentation URLs (space-separated)"
  echo_gray "  These will be added to the static resources list"
  echo_gray "  Example: https://docs.example.com https://wiki.mycompany.com"
  echo ""
  echo_green -n "  URLs (or Enter to skip): "
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

  # Show summary
  echo ""
  local final_sitemap_count=$(jq '.sitemaps | length' "$json_file" 2>/dev/null || echo "0")
  local final_static_count=$(jq '.static | length' "$json_file" 2>/dev/null || echo "0")
  print_success "Learning sources configured: $final_sitemap_count sitemaps, $final_static_count static"
  print_info "Edit directly: $json_file"
}

###############################################################################
# Section: Banner
###############################################################################
setup_section_banner() {
  print_header "ASCII Art Banner"

  if [ -z "${SETUP_USER_NAME:-}" ]; then
    if [ -f "$CONFIG_FILE" ]; then
      source "$CONFIG_FILE" 2>/dev/null
      SETUP_USER_NAME="${GOODMORNING_USER_NAME:-$USER}"
    else
      SETUP_USER_NAME="$USER"
    fi
  fi

  echo ""
  echo_blue "  Generate a custom ASCII art banner with your name"
  echo_blue "  Displayed at the start of each morning briefing"
  echo ""
  echo_cyan "  Name: $SETUP_USER_NAME"
  echo_gray "  (Requires figlet to be installed)"
  echo ""
  echo_green -n "  Generate custom banner? [y/N]: "
  read -r generate_banner

  if [[ $generate_banner =~ ^[Yy]$ ]]; then
    if command -v figlet &> /dev/null; then
      local banner_file="$CONFIG_DIR/banner.txt"
      {
        figlet -f standard "GOOD MORNING" 2>/dev/null || figlet "GOOD MORNING"
        echo ""
        figlet -f standard "${SETUP_USER_NAME}" 2>/dev/null || figlet "${SETUP_USER_NAME}"
      } > "$banner_file"
      print_success "Banner created at: $banner_file"
    else
      print_warning "figlet is not installed"
      echo_cyan "Install with: $(echo_green 'brew install figlet')"
    fi
  else
    print_info "Using default banner"
  fi
}

###############################################################################
# Section: Briefing Features
###############################################################################
setup_section_features() {
  print_header "Briefing Features"

  echo ""
  echo_blue "  Choose which sections to include in your morning briefing."
  echo_blue "  Each feature can be individually enabled or disabled."
  echo ""

  # Helper function to ask about a feature
  ask_feature() {
    local var_name="$1"
    local description="$2"
    local default="${3:-true}"
    local extra_prompt="$4"

    local default_display="Y/n"
    [[ "$default" != "true" ]] && default_display="y/N"

    echo ""
    echo_yellow "━━━ $description ━━━"
    echo ""
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

  # Ask about each feature
  ask_feature "SHOW_WEATHER" "Weather Forecast" "true"
  ask_feature "SHOW_HISTORY" "On This Day in History" "true"
  ask_feature "SHOW_TECH_VERSIONS" "Latest Tech Versions (Ruby, Rails, etc.)" "true"
  ask_feature "SHOW_COUNTRY" "Country of the Day" "true"
  ask_feature "SHOW_WORD" "Word of the Day" "true"
  ask_feature "SHOW_WIKIPEDIA" "Wikipedia Featured Article" "true"
  ask_feature "SHOW_APOD" "NASA Astronomy Picture of the Day" "true"
  ask_feature "SHOW_CALENDAR" "Calendar Events" "true"

  # Reminders with list name prompt
  ask_feature "SHOW_REMINDERS" "macOS Reminders" "true" '
    echo ""
    echo_blue "  Which reminder list should be displayed?"
    echo_gray "  (Leave blank for all incomplete reminders)"
    echo ""
    echo_green -n "  Reminder list name: "
    read -r SETUP_REMINDERS_LIST
  '

  ask_feature "SHOW_EMAIL" "Unread Email Summary" "true"
  ask_feature "SHOW_LEARNING" "Daily Learning Resources" "true"
  ask_feature "SHOW_SANITY" "Sanity Maintenance (Comics/Fun)" "true"
  ask_feature "SHOW_TIPS" "AI Learning Tips (requires Claude)" "true"
  ask_feature "RUN_UPDATES" "Background System Updates" "true"

  # Email briefing option
  echo ""
  echo_yellow "━━━ Email Briefing ━━━"
  echo ""
  echo_blue "  Send the morning briefing to your email address"
  echo ""
  echo_green -n "  Enable email briefing? [y/N]: "
  read -r email_response

  if [[ $email_response =~ ^[Yy]$ ]]; then
    SETUP_EMAIL_BRIEFING="true"
    echo ""
    echo_green -n "  Email address: "
    read -r SETUP_EMAIL_RECIPIENT

    echo ""
    echo_cyan "  Default subject: Morning Briefing"
    echo_green -n "  Custom subject (Enter for default): "
    read -r custom_subject
    SETUP_EMAIL_SUBJECT="${custom_subject:-Morning Briefing}"
  else
    SETUP_EMAIL_BRIEFING="false"
    SETUP_EMAIL_RECIPIENT=""
    SETUP_EMAIL_SUBJECT="Morning Briefing"
  fi

  print_success "Briefing features configured"
}

###############################################################################
# Section: Installation
###############################################################################
setup_section_install() {
  print_header "Installation"

  mkdir -p "$INSTALL_DIR"
  mkdir -p "$CONFIG_DIR"

  # Write config file
  cat > "$CONFIG_FILE" << EOF
# Good Morning Script Configuration
# Generated by setup.sh

export GOODMORNING_CONFIG_DIR="${CONFIG_DIR}"
export GOODMORNING_USER_NAME="${SETUP_USER_NAME:-\$USER}"
export GOODMORNING_ENABLE_TTS="${SETUP_ENABLE_TTS:-false}"
export GOODMORNING_BACKUP_SCRIPT="${SETUP_BACKUP_SCRIPT:-}"
export GOODMORNING_VIM_PLUGINS_DIR="${SETUP_VIM_PLUGINS_DIR:-\$HOME/.vim/pack/vendor/start}"
export GOODMORNING_PROJECT_DIRS="${SETUP_PROJECT_DIRS:-\$HOME}"
export GOODMORNING_LOGS_DIR="${CONFIG_DIR}/logs"
export GOODMORNING_OUTPUT_HISTORY_DIR="${CONFIG_DIR}/output_history"

# Briefing feature flags
export GOODMORNING_SHOW_WEATHER="${SETUP_SHOW_WEATHER:-true}"
export GOODMORNING_SHOW_HISTORY="${SETUP_SHOW_HISTORY:-true}"
export GOODMORNING_SHOW_TECH_VERSIONS="${SETUP_SHOW_TECH_VERSIONS:-true}"
export GOODMORNING_SHOW_COUNTRY="${SETUP_SHOW_COUNTRY:-true}"
export GOODMORNING_SHOW_WORD="${SETUP_SHOW_WORD:-true}"
export GOODMORNING_SHOW_WIKIPEDIA="${SETUP_SHOW_WIKIPEDIA:-true}"
export GOODMORNING_SHOW_APOD="${SETUP_SHOW_APOD:-true}"
export GOODMORNING_SHOW_CALENDAR="${SETUP_SHOW_CALENDAR:-true}"
export GOODMORNING_SHOW_REMINDERS="${SETUP_SHOW_REMINDERS:-true}"
export GOODMORNING_REMINDERS_LIST="${SETUP_REMINDERS_LIST:-}"
export GOODMORNING_SHOW_EMAIL="${SETUP_SHOW_EMAIL:-true}"
export GOODMORNING_SHOW_LEARNING="${SETUP_SHOW_LEARNING:-true}"
export GOODMORNING_SHOW_SANITY="${SETUP_SHOW_SANITY:-true}"
export GOODMORNING_SHOW_TIPS="${SETUP_SHOW_TIPS:-true}"
export GOODMORNING_RUN_UPDATES="${SETUP_RUN_UPDATES:-true}"

# Email briefing
export GOODMORNING_EMAIL_BRIEFING="${SETUP_EMAIL_BRIEFING:-false}"
export GOODMORNING_EMAIL_RECIPIENT="${SETUP_EMAIL_RECIPIENT:-}"
export GOODMORNING_EMAIL_SUBJECT="${SETUP_EMAIL_SUBJECT:-Morning Briefing}"
EOF

  print_success "Configuration saved to $CONFIG_FILE"

  # Create symlinks
  print_info "Creating symlinks in $INSTALL_DIR..."

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
      print_success "Symlinked $file"
    fi
  done

  print_header "Setup Complete"

  echo ""
  echo_cyan "To use the script, add this to your ~/.zshrc:"
  echo_green "  source $CONFIG_FILE"
  echo_green "  alias gm=\"$INSTALL_DIR/goodmorning.sh\""
  echo ""
  echo_cyan "Or run now with: $(echo_green './setup.sh --run')"
  echo ""
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
      echo ""
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
    echo ""
    echo "Run $(echo_green './setup.sh') to create a configuration."
    exit 1
  fi

  print_header "Current Configuration"
  echo ""

  source "$CONFIG_FILE"

  echo_cyan "Configuration file: $CONFIG_FILE"
  echo ""

  echo_yellow "User Name:"
  echo "  ${GOODMORNING_USER_NAME:-\$USER}"
  echo ""

  echo_yellow "Text-to-Speech:"
  echo "  ${GOODMORNING_ENABLE_TTS:-false}"
  echo ""

  echo_yellow "Backup Script:"
  if [ -n "$GOODMORNING_BACKUP_SCRIPT" ]; then
    echo "  $GOODMORNING_BACKUP_SCRIPT"
  else
    echo_gray "  (not configured)"
  fi
  echo ""

  echo_yellow "Learning Sources:"
  local json_file="${GOODMORNING_CONFIG_DIR:-$CONFIG_DIR}/learning-sources.json"
  if [ -f "$json_file" ]; then
    local sitemap_count=$(jq '.sitemaps | length' "$json_file" 2>/dev/null || echo "0")
    local static_count=$(jq '.static | length' "$json_file" 2>/dev/null || echo "0")
    echo "  $json_file"
    echo_blue "  Sitemaps: $sitemap_count, Static: $static_count"
  else
    echo_gray "  (not configured)"
  fi
  echo ""
}

run_goodmorning() {
  if [ ! -f "$CONFIG_FILE" ]; then
    print_warning "No configuration file found. Running setup first..."
    run_interactive_setup
  fi

  print_header "Running Good Morning Script"
  source "$CONFIG_FILE"
  exec "$SCRIPT_DIR/goodmorning.sh"
}

show_usage() {
  echo_cyan "Good Morning Script Setup"
  echo ""
  echo_yellow "Usage:"
  echo "  ./setup.sh                    Run full interactive setup"
  echo "  ./setup.sh --section <name>   Configure only one section"
  echo "  ./setup.sh --run              Run setup (if needed) then execute"
  echo "  ./setup.sh --reconfigure      Force re-running full setup"
  echo "  ./setup.sh --show-config      Display current configuration"
  echo "  ./setup.sh --help             Show this help message"
  echo ""
  echo_yellow "Sections:"
  echo "  system   - Check system requirements and dependencies"
  echo "  basic    - User name, TTS, config directory"
  echo "  paths    - Backup script, vim plugins, project directories"
  echo "  learning - Learning sources (sitemaps and static URLs)"
  echo "  banner   - ASCII art banner generation"
  echo "  install  - Write config file and create symlinks"
  echo ""
  echo_yellow "Examples:"
  echo_green "  ./setup.sh --section learning"
  echo "    Configure only learning sources"
  echo ""
  echo_green "  ./setup.sh --section banner"
  echo "    Regenerate ASCII art banner"
  echo ""
  echo_yellow "Configuration:"
  echo "  Config directory: $(echo_cyan "$CONFIG_DIR")"
  echo "  Config file:      $(echo_cyan "$CONFIG_FILE")"
  echo ""
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
  --run)
    run_goodmorning
    ;;
  --regenerate-banner)
    setup_section_banner
    ;;
  --section)
    if [ -z "$2" ]; then
      print_error "Section name required"
      echo ""
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
    echo ""
    show_usage
    exit 1
    ;;
esac
