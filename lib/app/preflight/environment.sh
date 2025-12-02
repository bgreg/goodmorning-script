#!/usr/bin/env zsh

###############################################################################
# Environment Preflight Checks
#
# Validates the execution environment for goodmorning script.
# Failures in these checks should STOP script execution.
#
# Checks:
# - Operating System (macOS required)
# - Shell (zsh required)
# - Terminal type (iTerm2 recommended)
# - Directory structure and permissions
###############################################################################

###############################################################################
# check_os - Verify running on macOS
#
# Returns: 0 if macOS, 1 otherwise
###############################################################################
check_os() {
  [[ "$OSTYPE" == "darwin"* ]]
}

###############################################################################
# check_shell - Verify running in zsh
#
# Returns: 0 if zsh, 1 otherwise
###############################################################################
check_shell() {
  [[ -n "$ZSH_VERSION" ]]
}

###############################################################################
# check_terminal - Detect terminal type
#
# Returns: 0 if iTerm2, 1 otherwise (non-fatal for basic operation)
###############################################################################
check_terminal() {
  [[ "$TERM_PROGRAM" == "iTerm.app" ]] || [[ "$LC_TERMINAL" == "iTerm2" ]]
}

###############################################################################
# check_directories - Validate required directories exist and are accessible
#
# Returns: 0 if all directories valid, 1 if any missing or inaccessible
###############################################################################
check_directories() {
  local config_dir="${GOODMORNING_CONFIG_DIR:-$HOME/.config/goodmorning}"
  local script_dir="${SCRIPT_DIR:-.}"

  # Check script directory exists and is readable
  [[ -d "$script_dir" ]] && [[ -r "$script_dir" ]] || return 1

  # Config directory can be created if missing, so just check parent
  local parent_dir=$(dirname "$config_dir")
  [[ -d "$parent_dir" ]] && [[ -w "$parent_dir" ]] || return 1

  return 0
}

###############################################################################
# check_permissions - Validate script has necessary permissions
#
# Returns: 0 if permissions OK, 1 otherwise
###############################################################################
check_permissions() {
  local script_dir="${SCRIPT_DIR:-.}"

  # Verify we can read lib directory
  [[ -r "$script_dir/lib" ]] || return 1

  # Verify we can execute scripts (check one critical file)
  [[ -r "$script_dir/lib/core.sh" ]] || return 1

  return 0
}
