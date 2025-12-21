#!/usr/bin/env zsh

###############################################################################
# Section Registry - Dependency Management for Briefing Sections
#
# Provides a registration system for sections to declare their dependencies
# (tools, network requirements). This enables:
# - Preflight checks to skip sections with missing dependencies
# - Doctor mode to report which sections are available
# - Clean separation of dependency metadata from section logic
#
# Usage in section files:
#   register_section "astronomy_picture" \
#     --tools "curl" "jq" \
#     --network
#
# Query functions:
#   section_requires_network "astronomy_picture"  # returns 0 (true) or 1 (false)
#   section_get_tools "astronomy_picture"         # echoes tool list
#   section_check_deps "astronomy_picture"        # returns 0 if all deps met
###############################################################################

# Storage: associative arrays keyed by section name
typeset -gA SECTION_REGISTRY_TOOLS
typeset -gA SECTION_REGISTRY_NETWORK

###############################################################################
# register_section - Declare a section's dependencies
#
# Usage: register_section "section_name" [--tools tool1 tool2 ...] [--network]
#
# Arguments:
#   section_name  - Unique identifier for the section (e.g., "astronomy_picture")
#   --tools       - List of required CLI tools (curl, jq, gh, etc.)
#   --network     - Flag indicating section requires network connectivity
#
# Example:
#   register_section "github_notifications" --tools "gh" "jq" --network
#   register_section "system_info" --tools "sw_vers"
###############################################################################
register_section() {
  local section_name="$1"
  shift

  local tools=()
  local needs_network=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tools)
        shift
        while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
          tools+=("$1")
          shift
        done
        ;;
      --network)
        needs_network=true
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  # Store in registry
  SECTION_REGISTRY_TOOLS[$section_name]="${tools[*]}"
  SECTION_REGISTRY_NETWORK[$section_name]="$needs_network"
}

###############################################################################
# section_requires_network - Check if section needs network
#
# Returns: 0 if network required, 1 if not (or section not registered)
###############################################################################
section_requires_network() {
  local section_name="$1"
  [[ "${SECTION_REGISTRY_NETWORK[$section_name]:-false}" == "true" ]]
}

###############################################################################
# section_get_tools - Get list of required tools for a section
#
# Returns: Space-separated list of tool names, or empty if none
###############################################################################
section_get_tools() {
  local section_name="$1"
  echo "${SECTION_REGISTRY_TOOLS[$section_name]:-}"
}

###############################################################################
# section_check_deps - Verify all dependencies are met for a section
#
# Returns: 0 if all dependencies satisfied, 1 if any missing
# Outputs: Names of missing dependencies to stderr
###############################################################################
section_check_deps() {
  local section_name="$1"
  local missing=()

  # Check tools
  local tools="${SECTION_REGISTRY_TOOLS[$section_name]:-}"
  if [[ -n "$tools" ]]; then
    for tool in ${=tools}; do
      if ! command -v "$tool" &>/dev/null; then
        missing+=("tool:$tool")
      fi
    done
  fi

  # Check network if required
  if section_requires_network "$section_name"; then
    if [[ "${GOODMORNING_FORCE_OFFLINE:-}" == "true" ]] || ! check_internet_quick 2>> "$LOG_FILE"; then
      missing+=("network")
    fi
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "${missing[*]}" >&2
    return 1
  fi

  return 0
}

###############################################################################
# section_is_registered - Check if a section has been registered
#
# Returns: 0 if registered, 1 if not
###############################################################################
section_is_registered() {
  local section_name="$1"
  [[ -n "${SECTION_REGISTRY_TOOLS[$section_name]+x}" ]] || \
  [[ -n "${SECTION_REGISTRY_NETWORK[$section_name]+x}" ]]
}

###############################################################################
# section_list_all - List all registered sections
#
# Returns: Newline-separated list of section names
###############################################################################
section_list_all() {
  local sections=()
  for key in "${(@k)SECTION_REGISTRY_TOOLS}"; do
    sections+=("$key")
  done
  for key in "${(@k)SECTION_REGISTRY_NETWORK}"; do
    [[ ! " ${sections[*]} " =~ " $key " ]] && sections+=("$key")
  done
  printf '%s\n' "${sections[@]}" | sort -u
}

###############################################################################
# section_print_deps - Print human-readable dependency info for a section
#
# Outputs formatted dependency information for display/debugging
###############################################################################
section_print_deps() {
  local section_name="$1"

  if ! section_is_registered "$section_name"; then
    echo "Section '$section_name' not registered"
    return 1
  fi

  echo "Section: $section_name"
  echo "  Tools: ${SECTION_REGISTRY_TOOLS[$section_name]:-none}"
  echo "  Network: ${SECTION_REGISTRY_NETWORK[$section_name]:-false}"
}
