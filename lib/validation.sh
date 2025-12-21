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

# Determine this file's directory (lib/)
_VALIDATION_LIB_DIR="${0:a:h}"

if [ -f "$_VALIDATION_LIB_DIR/setup/validation_helpers.sh" ]; then
  source "$_VALIDATION_LIB_DIR/setup/validation_helpers.sh"
else
  echo "Error: Could not find validation_helpers.sh" >&2
  return 1
fi

if [ -f "$_VALIDATION_LIB_DIR/setup/doctor.sh" ]; then
  source "$_VALIDATION_LIB_DIR/setup/doctor.sh"
else
  echo "Error: Could not find doctor.sh" >&2
  return 1
fi
