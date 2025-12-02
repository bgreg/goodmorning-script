#!/usr/bin/env zsh

###############################################################################
# Network Preflight Checks
#
# Detects internet connectivity for graceful degradation.
# Unlike environment checks, network failures should NOT stop execution.
# Instead, sections requiring network should skip gracefully.
###############################################################################

# Global network status cache
typeset -g NETWORK_ONLINE=""

###############################################################################
# check_internet - Quick internet connectivity check
#
# Uses multiple fast methods to detect connectivity:
# 1. DNS resolution of a reliable host
# 2. Quick ping to a reliable IP
#
# Sets NETWORK_ONLINE global variable to "true" or "false"
# Returns: Always returns 0 (never fails - just sets status)
###############################################################################
check_internet() {
  # Quick DNS check (faster than ping)
  if host -W 2 dns.google >/dev/null 2>&1; then
    NETWORK_ONLINE="true"
    return 0
  fi

  # Fallback: quick ping to Google DNS
  if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    NETWORK_ONLINE="true"
    return 0
  fi

  # No connectivity detected
  NETWORK_ONLINE="false"
  return 0
}

###############################################################################
# is_online - Check if network is available
#
# Returns: 0 if online, 1 if offline
# Usage: if is_online; then fetch_data; fi
###############################################################################
is_online() {
  [[ "$NETWORK_ONLINE" == "true" ]]
}

###############################################################################
# skip_if_offline - Helper for sections requiring network
#
# Returns: 0 (allowing section to be skipped when offline)
# Usage: skip_if_offline || return 0
###############################################################################
skip_if_offline() {
  if ! is_online; then
    return 0  # Return success to trigger skip
  fi
  return 1  # Return failure to continue execution
}
