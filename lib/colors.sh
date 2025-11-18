#!/usr/bin/env zsh

###############################################################################
# Color Constants and Output Helpers
#
# Provides color definitions and convenience functions for colored output.
# Used across all goodmorning modules for consistent terminal formatting.
###############################################################################

# ANSI color codes
ESC_SEQ="\x1b["
COLOR_RESET=$ESC_SEQ"39;49;00m"
COLOR_RED=$ESC_SEQ"31;01m"
COLOR_GREEN=$ESC_SEQ"32;01m"
COLOR_YELLOW=$ESC_SEQ"33;01m"
COLOR_BLUE=$ESC_SEQ"34;01m"
COLOR_MAGENTA=$ESC_SEQ"35;01m"
COLOR_CYAN=$ESC_SEQ"36;01m"
COLOR_GRAY=$ESC_SEQ"90m"

###############################################################################
# Color Output Helpers
#
# All functions support -n flag to suppress newline (like echo -n)
# Usage: echo_green "text"      # with newline
#        echo_green -n "text"   # without newline
###############################################################################

echo_red() {
  if [[ "$1" == "-n" ]]; then
    shift
    echo -en "${COLOR_RED}$*${COLOR_RESET}"
  else
    echo -e "${COLOR_RED}$*${COLOR_RESET}"
  fi
}

echo_green() {
  if [[ "$1" == "-n" ]]; then
    shift
    echo -en "${COLOR_GREEN}$*${COLOR_RESET}"
  else
    echo -e "${COLOR_GREEN}$*${COLOR_RESET}"
  fi
}

echo_yellow() {
  if [[ "$1" == "-n" ]]; then
    shift
    echo -en "${COLOR_YELLOW}$*${COLOR_RESET}"
  else
    echo -e "${COLOR_YELLOW}$*${COLOR_RESET}"
  fi
}

echo_blue() {
  if [[ "$1" == "-n" ]]; then
    shift
    echo -en "${COLOR_BLUE}$*${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}$*${COLOR_RESET}"
  fi
}

echo_magenta() {
  if [[ "$1" == "-n" ]]; then
    shift
    echo -en "${COLOR_MAGENTA}$*${COLOR_RESET}"
  else
    echo -e "${COLOR_MAGENTA}$*${COLOR_RESET}"
  fi
}

echo_cyan() {
  if [[ "$1" == "-n" ]]; then
    shift
    echo -en "${COLOR_CYAN}$*${COLOR_RESET}"
  else
    echo -e "${COLOR_CYAN}$*${COLOR_RESET}"
  fi
}

echo_gray() {
  if [[ "$1" == "-n" ]]; then
    shift
    echo -en "${COLOR_GRAY}$*${COLOR_RESET}"
  else
    echo -e "${COLOR_GRAY}$*${COLOR_RESET}"
  fi
}
