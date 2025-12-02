#!/usr/bin/env zsh

###############################################################################
# Validation Library - Compatibility Wrapper
#
# This file maintains backward compatibility by sourcing the modular
# validation components from lib/setup/
#
# Components:
#   - validation_helpers.sh: Core validation functions and display helpers
#   - doctor.sh: Doctor mode system diagnostics
###############################################################################

# Determine script directory
SCRIPT_DIR="${SCRIPT_DIR:-${0:a:h}}"

# Source validation helpers
if [ -f "$SCRIPT_DIR/setup/validation_helpers.sh" ]; then
  source "$SCRIPT_DIR/setup/validation_helpers.sh"
else
  echo "Error: Could not find validation_helpers.sh" >&2
  return 1
fi

# Source doctor mode
if [ -f "$SCRIPT_DIR/setup/doctor.sh" ]; then
  source "$SCRIPT_DIR/setup/doctor.sh"
else
  echo "Error: Could not find doctor.sh" >&2
  return 1
fi
