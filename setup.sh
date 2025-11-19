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

check_system_requirements() {
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

  echo ""
  echo_cyan "Checking optional dependencies..."

  if ! command -v brew &> /dev/null; then
    missing_optional+=("brew")
    print_warning "Homebrew not found (recommended for updates)"
  else
    print_success "Homebrew found"
  fi

  if ! command -v jq &> /dev/null; then
    missing_optional+=("jq")
    print_warning "jq not found (needed for history feature)"
  else
    print_success "jq found"
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
    exit 1
  fi

  if [ ${#missing_optional[@]} -gt 0 ]; then
    echo ""
    echo_yellow "Missing optional dependencies:"
    for dep in "${missing_optional[@]}"; do
      echo "  - $dep"
    done

    if [ "$interactive" = "true" ]; then
      if command -v brew &> /dev/null; then
        echo ""
        echo_cyan "Install missing optional dependencies with Homebrew?"
        echo_green -n "Install now? [y/N]: "
        read -r install_deps

        if [[ $install_deps =~ ^[Yy]$ ]]; then
          for dep in "${missing_optional[@]}"; do
            case "$dep" in
              "jq")
                brew install jq
                ;;
              "figlet")
                brew install figlet
                ;;
              "icalBuddy")
                brew install ical-buddy
                ;;
              "claude")
                echo_cyan "Install Claude Code with:"
                echo_green "  npm install -g @anthropic-ai/claude-code"
                ;;
            esac
          done
        fi
      else
        echo ""
        echo_cyan "Install Homebrew to easily install dependencies:"
        echo_green "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
      fi
    else
      echo ""
      echo_cyan "Install missing dependencies with:"
      if command -v brew &> /dev/null; then
        for dep in "${missing_optional[@]}"; do
          case "$dep" in
            "jq")
              echo_green "  brew install jq"
              ;;
            "figlet")
              echo_green "  brew install figlet"
              ;;
            "icalBuddy")
              echo_green "  brew install ical-buddy"
              ;;
            "claude")
              echo_green "  npm install -g @anthropic-ai/claude-code"
              ;;
          esac
        done
      else
        echo_green "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
      fi
    fi
  else
    echo ""
    echo_green "All optional dependencies are installed!"
  fi

  echo ""
}

validate_file_path() {
  local path="$1"
  local make_absolute="${2:-true}"

  if [ -z "$path" ]; then
    return 0
  fi

  # Check for dangerous characters using glob patterns instead of regex
  if [[ "$path" == *'$('* ]] || [[ "$path" == *'`'* ]] || [[ "$path" == *';'* ]] || [[ "$path" == *'|'* ]]; then
    print_error "Invalid characters in path: $path"
    return 1
  fi

  if [ "$make_absolute" = "true" ] && [[ ! "$path" = /* ]]; then
    local dir_part=$(dirname "$path")
    local file_part=$(basename "$path")

    if [ ! -d "$dir_part" ]; then
      print_error "Directory not found: $dir_part"
      return 1
    fi

    local abs_dir=$(cd "$dir_part" 2>/dev/null && pwd)
    if [ -z "$abs_dir" ]; then
      print_error "Cannot resolve directory: $dir_part"
      return 1
    fi

    path="${abs_dir}/${file_part}"
  fi

  if [ ! -f "$path" ]; then
    print_error "File not found: $path"
    return 1
  fi

  if [ ! -x "$path" ]; then
    print_warning "File exists but is not executable: $path"
    echo_green -n "Make it executable? [y/N]: "
    read -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      chmod +x "$path"
      print_success "Made executable: $path"
    fi
  fi

  echo "$path"
  return 0
}

validate_directory_path() {
  local path="$1"
  local make_absolute="${2:-true}"

  if [ -z "$path" ]; then
    return 0
  fi

  if [ "$make_absolute" = "true" ] && [[ ! "$path" = /* ]]; then
    path="$(cd "$path" 2>/dev/null && pwd)"
  fi

  if [ ! -d "$path" ]; then
    print_error "Directory not found: $path"
    return 1
  fi

  echo "$path"
  return 0
}

prompt_for_variable() {
  local var_name="$1"
  local purpose="$2"
  local default_value="$3"
  local current_value="$4"
  local validator="$5"

  echo "" >&2
  echo_yellow "━━━ ${var_name} ━━━" >&2
  echo "" >&2
  echo_blue "  Purpose: $purpose" >&2
  echo "" >&2

  local display_default="${current_value:-$default_value}"

  if [ -n "$display_default" ]; then
    echo_cyan "  Default: $display_default" >&2
    echo_gray "  (Press Enter to use default)" >&2
  else
    echo_gray "  (Optional - press Enter to skip)" >&2
  fi

  while true; do
    echo "" >&2
    echo_green -n "  Your choice: " >&2
    read -r user_input

    if [ -z "$user_input" ]; then
      if [ -n "$current_value" ]; then
        echo "$current_value"
      elif [ -n "$default_value" ]; then
        echo "$default_value"
      fi
      return 0
    fi

    if [ -n "$validator" ]; then
      validated_value=$($validator "$user_input")
      if [ $? -eq 0 ]; then
        echo "$validated_value"
        return 0
      fi
    else
      echo "$user_input"
      return 0
    fi
  done
}

run_interactive_setup() {
  check_system_requirements

  print_header "Good Morning Script Setup"

  echo ""
  echo_cyan "This will guide you through configuring the Good Morning script."
  echo_cyan "Each prompt explains what the setting does and shows the default value."
  echo_cyan "Press Enter to accept defaults, or type your own value."
  echo ""

  local current_user_name=""
  local current_backup_script=""
  local current_vim_plugins_dir=""
  local current_project_dirs=""
  local current_enable_tts=""
  local current_config_dir=""

  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE" 2>/dev/null
    current_user_name="${GOODMORNING_USER_NAME:-}"
    current_backup_script="${GOODMORNING_BACKUP_SCRIPT:-}"
    current_vim_plugins_dir="${GOODMORNING_VIM_PLUGINS_DIR:-}"
    current_project_dirs="${GOODMORNING_PROJECT_DIRS:-}"
    current_enable_tts="${GOODMORNING_ENABLE_TTS:-false}"
    current_config_dir="${GOODMORNING_CONFIG_DIR:-}"
  fi

  # Config directory prompt
  echo ""
  echo_yellow "━━━ Configuration Directory ━━━"
  echo ""
  echo_blue "  Purpose: Where to store your Good Morning configuration files"
  echo_blue "           (config.sh, banner.txt, learning-sources.txt)"
  echo ""
  echo_cyan "  Default: $DEFAULT_CONFIG_DIR"
  echo_gray "  (Press Enter to use default)"
  echo ""
  echo_green -n "  Your choice: "
  read -r config_dir_input

  if [ -n "$config_dir_input" ]; then
    # Expand ~ to $HOME
    config_dir_input="${config_dir_input/#\~/$HOME}"
    CONFIG_DIR="$config_dir_input"
    CONFIG_FILE="$CONFIG_DIR/config.sh"
  elif [ -n "$current_config_dir" ]; then
    CONFIG_DIR="$current_config_dir"
    CONFIG_FILE="$CONFIG_DIR/config.sh"
  fi

  user_name=$(prompt_for_variable \
    "Your Name" \
    "Used for the personalized morning greeting banner" \
    "$USER" \
    "$current_user_name")

  echo ""
  echo_yellow "━━━ Text-to-Speech Greeting ━━━"
  echo ""
  echo_blue "  Purpose: Audibly announce 'Good morning' using macOS text-to-speech"
  echo_blue "           Useful for a more engaging morning ritual"
  echo ""
  echo_cyan "  Default: disabled"
  if [ "$current_enable_tts" = "true" ]; then
    echo_cyan "  Current: enabled"
  fi
  echo_gray "  (Requires macOS 'say' command)"
  echo ""
  echo_green -n "  Enable text-to-speech? [y/N]: "
  read -r enable_tts_input

  if [[ $enable_tts_input =~ ^[Yy]$ ]]; then
    enable_tts="true"
  else
    enable_tts="false"
  fi

  backup_script=$(prompt_for_variable \
    "Backup Script" \
    "Path to a script that runs backups (e.g., Time Machine, rsync).
           The script will be executed in the background during your morning routine." \
    "" \
    "$current_backup_script" \
    "validate_file_path")

  vim_plugins_dir=$(prompt_for_variable \
    "Vim Plugins Directory" \
    "Directory containing your Vim plugins for automatic updates.
           Leave empty if you don't use Vim or manage plugins differently." \
    "\$HOME/.vim/pack/vendor/start" \
    "$current_vim_plugins_dir" \
    "validate_directory_path")

  echo ""
  echo_yellow "━━━ Project Directories ━━━"
  echo ""
  echo_blue "  Purpose: Directories to scan for git repositories"
  echo_blue "           Used to check for uncommitted changes across your projects"
  echo ""
  echo_cyan "  Default: \$HOME"
  if [ -n "$current_project_dirs" ]; then
    echo_cyan "  Current: $current_project_dirs"
  fi
  echo_gray "  (Separate multiple paths with colons or spaces)"
  echo_gray "  Example: ~/workspace:~/projects"
  echo ""
  echo_green -n "  Your choice: "
  read -r project_dirs_input

  if [ -z "$project_dirs_input" ]; then
    if [ -n "$current_project_dirs" ]; then
      project_dirs="$current_project_dirs"
    else
      project_dirs="$HOME"
    fi
  else
    validated_dirs=""
    for dir in ${project_dirs_input//[: ]/ }; do
      if [[ ! "$dir" = /* ]]; then
        dir="$(cd "$dir" 2>/dev/null && pwd)" || continue
      fi
      if [ -d "$dir" ]; then
        if [ -z "$validated_dirs" ]; then
          validated_dirs="$dir"
        else
          validated_dirs="$validated_dirs:$dir"
        fi
      else
        print_warning "Directory not found: $dir (skipping)"
      fi
    done
    project_dirs="$validated_dirs"
  fi

  mkdir -p "$CONFIG_DIR"

  # Learning Sites Selection
  echo ""
  echo_yellow "━━━ Learning Sites ━━━"
  echo ""
  echo_blue "  Purpose: Configure which documentation sites to randomly select from"
  echo_blue "           for your daily learning suggestion. Uses sitemaps to find"
  echo_blue "           relevant documentation pages."
  echo ""
  echo_cyan "  Available sources (toggle with numbers, Enter when done):"
  echo ""

  # Define available learning sources
  local -a source_names source_categories source_urls
  source_names=(
    "PostgreSQL Documentation"
    "Ruby on Rails Guides"
    "MDN Web Docs (JavaScript/HTML/CSS)"
    "Ruby Core & Standard Library"
    "JavaScript Tutorials"
    "Zsh Documentation"
  )
  source_categories=(
    "PostgreSQL Docs"
    "Ruby on Rails Guides"
    "MDN Web Docs"
    "Ruby Core"
    "JavaScript Tutorials"
    "Zsh Tips"
  )
  source_urls=(
    "sitemap:https://www.postgresql.org/docs/sitemap.xml"
    "sitemap:https://guides.rubyonrails.org/sitemap.xml.gz"
    "sitemap:https://developer.mozilla.org/sitemaps/en-us/sitemap.xml.gz"
    "https://ruby-doc.org/core/|Ruby Core Documentation\nhttps://ruby-doc.org/stdlib/|Ruby Standard Library"
    "https://javascript.info/|The Modern JavaScript Tutorial\nhttps://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide|MDN JavaScript Guide"
    "https://zsh.sourceforge.io/Doc/|Zsh Documentation\nhttps://github.com/ohmyzsh/ohmyzsh/wiki|Oh My Zsh Wiki"
  )

  # Initialize selected sources (all enabled by default)
  local -a selected_sources
  for i in {1..${#source_names[@]}}; do
    selected_sources[$i]=1
  done

  # Display sources with toggle numbers
  local done_selecting=false
  while [ "$done_selecting" = "false" ]; do
    for i in {1..${#source_names[@]}}; do
      if [ "${selected_sources[$i]}" -eq 1 ]; then
        echo_green "    [$i] ✓ ${source_names[$i]}"
      else
        echo_gray "    [$i]   ${source_names[$i]}"
      fi
    done
    echo ""
    echo_gray "  Enter number to toggle, or press Enter to continue"
    echo_green -n "  Toggle: "
    read -r toggle_input

    if [ -z "$toggle_input" ]; then
      done_selecting=true
    elif [[ "$toggle_input" =~ ^[0-9]+$ ]] && [ "$toggle_input" -ge 1 ] && [ "$toggle_input" -le ${#source_names[@]} ]; then
      if [ "${selected_sources[$toggle_input]}" -eq 1 ]; then
        selected_sources[$toggle_input]=0
      else
        selected_sources[$toggle_input]=1
      fi
      # Clear and redraw the list
      echo ""
    fi
  done

  # Generate learning-sources.txt based on selections
  local learning_file="$CONFIG_DIR/learning-sources.txt"
  {
    echo "# Daily Learning Sources"
    echo "#"
    echo "# Format:"
    echo "#   [Category Name]"
    echo "#   sitemap:https://example.com/sitemap.xml"
    echo "#   or"
    echo "#   URL|Title"
    echo ""
  } > "$learning_file"

  local any_selected=false
  for i in {1..${#source_names[@]}}; do
    if [ "${selected_sources[$i]}" -eq 1 ]; then
      any_selected=true
      echo "" >> "$learning_file"
      echo "[${source_categories[$i]}]" >> "$learning_file"
      echo "${source_urls[$i]}" >> "$learning_file"
    fi
  done

  if [ "$any_selected" = "true" ]; then
    print_success "Learning sources configured in: $learning_file"
  else
    echo_yellow "  No learning sources selected"
    print_info "You can add custom sources later by editing: $learning_file"
  fi

  if [ -n "$user_name" ]; then
    echo ""
    echo_yellow "━━━ ASCII Art Banner ━━━"
    echo ""
    echo_blue "  Purpose: Generate a custom ASCII art banner with your name"
    echo_blue "           Displayed at the start of each morning briefing"
    echo ""
    echo_cyan "  Default: disabled"
    echo_gray "  (Requires figlet to be installed)"
    echo ""
    echo_green -n "  Generate custom banner? [y/N]: "
    read -r generate_banner

    if [[ $generate_banner =~ ^[Yy]$ ]]; then
      if command -v figlet &> /dev/null; then
        echo ""
        echo_cyan "Generating ASCII art banner for: Good Morning ${user_name}"
        local banner_file="$CONFIG_DIR/banner.txt"
        {
          figlet -f standard "GOOD MORNING" 2>/dev/null || figlet "GOOD MORNING"
          echo ""
          figlet -f standard "${user_name}" 2>/dev/null || figlet "${user_name}"
        } > "$banner_file"
        print_success "Banner created at: $banner_file"
      else
        print_warning "figlet is not installed"
        echo_cyan "Install with: $(echo_green 'brew install figlet')"
        echo_yellow "Using default banner for now"
      fi
    else
      print_info "Using default banner"
    fi
  else
    print_warning "No user name provided, skipping banner generation"
  fi

  cat > "$CONFIG_FILE" << EOF
# Good Morning Script Configuration
# Generated by setup.sh

export GOODMORNING_CONFIG_DIR="${CONFIG_DIR}"
export GOODMORNING_USER_NAME="${user_name:-\$USER}"
export GOODMORNING_ENABLE_TTS="${enable_tts:-false}"
export GOODMORNING_BACKUP_SCRIPT="${backup_script}"
export GOODMORNING_VIM_PLUGINS_DIR="${vim_plugins_dir:-\$HOME/.vim/pack/vendor/start}"
export GOODMORNING_PROJECT_DIRS="${project_dirs:-\$HOME}"
EOF

  mkdir -p "$INSTALL_DIR"

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
    else
      print_warning "Source file not found: $source_file"
    fi
  done

  print_header "Configuration Complete"
  print_success "Configuration saved to $CONFIG_FILE"
  print_success "Scripts installed to $INSTALL_DIR"

  echo ""
  echo_cyan "To use the script, add this to your ~/.zshrc or ~/.bashrc:"
  echo_green "  source $CONFIG_FILE"
  echo_green "  alias gm=\"$INSTALL_DIR/goodmorning.sh\""

  echo ""
  echo_cyan "Or run now with: $(echo_green './setup.sh --run')"
  echo ""
}

show_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    print_error "No configuration file found at $CONFIG_FILE"
    echo ""
    echo "Run $(echo_green './setup.sh') to create a configuration."
    echo ""
    exit 1
  fi

  print_header "Current Configuration"
  echo ""

  source "$CONFIG_FILE"

  # Use config's directory if set
  local display_config_dir="${GOODMORNING_CONFIG_DIR:-$CONFIG_DIR}"

  echo_cyan "Installation directory: $INSTALL_DIR"
  echo_cyan "Configuration directory: $display_config_dir"
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
    if [ -f "$GOODMORNING_BACKUP_SCRIPT" ]; then
      print_success "File exists"
    else
      print_error "File not found"
    fi
  else
    echo_blue "  (not configured)"
  fi
  echo ""

  echo_yellow "Vim Plugins Directory:"
  echo "  ${GOODMORNING_VIM_PLUGINS_DIR:-\$HOME/.vim/pack/vendor/start}"
  if [ -d "${GOODMORNING_VIM_PLUGINS_DIR:-$HOME/.vim/pack/vendor/start}" ]; then
    print_success "Directory exists"
  else
    print_warning "Directory not found"
  fi
  echo ""

  echo_yellow "Project Directories:"
  for dir in ${(s.:.)GOODMORNING_PROJECT_DIRS:-$HOME}; do
    echo "  $dir"
    if [ -d "$dir" ]; then
      print_success "Directory exists"
    else
      print_error "Directory not found"
    fi
  done
  echo ""

  echo_yellow "Learning Sources:"
  local learning_file="${display_config_dir}/learning-sources.txt"
  if [ -f "$learning_file" ]; then
    echo "  $learning_file"
    print_success "File exists"
    local categories=$(grep -c '^\[' "$learning_file" 2>/dev/null || echo "0")
    echo_blue "  Categories configured: $categories"
  else
    echo_blue "  (not configured)"
    print_info "Run './setup.sh --reconfigure' to set up learning sources"
  fi
  echo ""
}

run_goodmorning() {
  if [ ! -f "$CONFIG_FILE" ]; then
    print_warning "No configuration file found. Running interactive setup first..."
    run_interactive_setup
  fi

  print_header "Running Good Morning Script"
  source "$CONFIG_FILE"
  exec "$SCRIPT_DIR/goodmorning.sh"
}

regenerate_banner() {
  print_header "Regenerate ASCII Art Banner"

  if [ ! -f "$CONFIG_FILE" ]; then
    print_error "No configuration file found at $CONFIG_FILE"
    echo ""
    echo "Run $(echo_green './setup.sh') to create a configuration."
    echo ""
    exit 1
  fi

  source "$CONFIG_FILE"
  local user_name="${GOODMORNING_USER_NAME:-$USER}"

  echo ""
  echo_cyan "Current user name: $user_name"
  echo_green "Use this name or enter a new one (press Enter to keep current): "
  read -r new_name

  if [ -n "$new_name" ]; then
    user_name="$new_name"
  fi

  if [ -z "$user_name" ]; then
    print_error "No user name provided"
    exit 1
  fi

  if ! command -v figlet &> /dev/null; then
    print_error "figlet is not installed"
    echo_cyan "Install with: $(echo_green 'brew install figlet')"
    echo ""
    exit 1
  fi

  mkdir -p "$CONFIG_DIR"
  local banner_file="$CONFIG_DIR/banner.txt"

  if [ -f "$banner_file" ]; then
    echo ""
    echo_yellow "Current banner:"
    cat "$banner_file"
    echo ""
  fi

  echo_cyan "Generating new ASCII art banner for: Good Morning ${user_name}"
  {
    figlet -f standard "GOOD MORNING" 2>/dev/null || figlet "GOOD MORNING"
    echo ""
    figlet -f standard "${user_name}" 2>/dev/null || figlet "${user_name}"
  } > "$banner_file"

  echo ""
  echo_green "New banner:"
  cat "$banner_file"
  echo ""

  print_success "Banner updated at: $banner_file"

  if [ "$user_name" != "${GOODMORNING_USER_NAME:-$USER}" ]; then
    echo ""
    echo_yellow "Note: GOODMORNING_USER_NAME is still set to: ${GOODMORNING_USER_NAME:-$USER}"
    echo_cyan "To update it, run: $(echo_green './setup.sh --reconfigure')"
    echo ""
  fi
}

show_usage() {
  echo_cyan "Good Morning Script Setup"
  echo ""
  echo_yellow "Usage:"
  echo "  ./setup.sh              Run interactive setup"
  echo "  ./setup.sh --run        Run setup (if needed) then execute goodmorning.sh"
  echo "  ./setup.sh --reconfigure   Force re-running setup even if config exists"
  echo "  ./setup.sh --show-config   Display current configuration"
  echo "  ./setup.sh --check-system  Check system requirements and dependencies"
  echo "  ./setup.sh --regenerate-banner   Regenerate ASCII art banner with figlet"
  echo "  ./setup.sh --help       Show this help message"
  echo ""
  echo_yellow "Examples:"
  echo_green "  ./setup.sh"
  echo "    Run interactive configuration wizard"
  echo ""
  echo_green "  ./setup.sh --run"
  echo "    Configure (if needed) and run the good morning script"
  echo ""
  echo_green "  ./setup.sh --show-config"
  echo "    Display current configuration and verify paths"
  echo ""
  echo_green "  ./setup.sh --check-system"
  echo "    Verify macOS and check for required/optional dependencies"
  echo ""
  echo_green "  ./setup.sh --regenerate-banner"
  echo "    Generate a new custom ASCII art banner using figlet"
  echo ""
  echo_green "  GOODMORNING_INSTALL_DIR=/custom/path ./setup.sh"
  echo "    Install to a custom directory (default: $DEFAULT_INSTALL_DIR)"
  echo ""
  echo_green "  GOODMORNING_CONFIG_DIR=/custom/config ./setup.sh"
  echo "    Use a custom config directory (default: $DEFAULT_CONFIG_DIR)"
  echo ""
  echo_yellow "Configuration:"
  echo "  Install directory:   $(echo_cyan "$INSTALL_DIR")"
  echo "  Config directory:    $(echo_cyan "$CONFIG_DIR")"
  echo "  Config file:         $(echo_cyan "$CONFIG_FILE")"
  echo "  Banner file:         $(echo_cyan "$CONFIG_DIR/banner.txt")"
  echo "  Learning sources:    $(echo_cyan "$CONFIG_DIR/learning-sources.txt")"
  echo ""
  echo_yellow "Environment Variables:"
  echo "  $(echo_cyan 'GOODMORNING_INSTALL_DIR')  Installation directory for symlinks"
  echo "                               (default: $DEFAULT_INSTALL_DIR)"
  echo "  $(echo_cyan 'GOODMORNING_CONFIG_DIR')   Configuration directory"
  echo "                               (default: $DEFAULT_CONFIG_DIR)"
  echo ""
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  show_usage
  exit 0
elif [ "$1" = "--show-config" ]; then
  show_config
  exit 0
elif [ "$1" = "--check-system" ]; then
  check_system_requirements false
  exit 0
elif [ "$1" = "--reconfigure" ]; then
  run_interactive_setup
  exit 0
elif [ "$1" = "--run" ]; then
  run_goodmorning
  exit 0
elif [ "$1" = "--regenerate-banner" ]; then
  regenerate_banner
  exit 0
elif [ -z "$1" ]; then
  run_interactive_setup
  exit 0
else
  print_error "Unknown option: $1"
  echo
  show_usage
  exit 1
fi
