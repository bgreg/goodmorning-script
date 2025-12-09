#!/usr/bin/env zsh

###############################################################################
# Bootstrap
#
# Sources all library files in correct order. SCRIPT_DIR must be set by the
# caller before sourcing this file.
#
# This file must be sourced, not executed directly.
###############################################################################

if [[ -z "$SCRIPT_DIR" ]]; then
  echo "Error: SCRIPT_DIR must be set before sourcing bootstrap.sh" >&2
  return 1
fi

###############################################################################
# Source Library Files
###############################################################################

# Source utilities first (provides _source_lib helper)
if [[ -f "$SCRIPT_DIR/lib/utilities.sh" ]]; then
  source "$SCRIPT_DIR/lib/utilities.sh"
else
  echo "Error: Required file missing: lib/utilities.sh" >&2
  return 1
fi

# Core dependencies (order matters)
_source_lib "lib/app/colors.sh" required
_source_lib "lib/app/core.sh" required

# Preflight checks
for module in environment network tools; do
  _source_lib "lib/app/preflight/${module}.sh"
done

# Core application modules
for module in config init updates display learning versions view_helpers; do
  _source_lib "lib/app/${module}.sh"
done

# Daily content sections
for section in country_of_day word_of_day wikipedia_featured astronomy_picture cat_of_day alias_suggestions common_typos system_info; do
  _source_lib "lib/app/sections/${section}.sh"
done

# Additional modules
for module in sanity_maintenance github; do
  _source_lib "lib/app/${module}.sh"
done
