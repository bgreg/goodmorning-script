#!/usr/bin/env zsh

###############################################################################
# System Information Section
#
# Displays macOS system information including version, uptime, disk, memory, and battery
###############################################################################

# Section dependencies
SECTION_DEPS_TOOLS=(sw_vers uptime df awk)
SECTION_DEPS_NETWORK=false

show_system_info() {
  print_section "💻 System Information:" "yellow"

  # macOS version
  local macos_version=$(sw_vers -productVersion 2>/dev/null)
  local macos_name=$(sw_vers -productName 2>/dev/null)
  if [ -n "$macos_version" ]; then
    echo "  macOS: $macos_name $macos_version"
  fi

  # Safari version
  local safari_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" /Applications/Safari.app/Contents/Info.plist 2>/dev/null)
  if [ -n "$safari_version" ]; then
    echo "  Safari: $safari_version"
  fi

  # Uptime (time since last reboot)
  local uptime_info=$(uptime | sed 's/.*up //' | sed 's/,.*//' | sed 's/^[ \t]*//')
  if [ -n "$uptime_info" ]; then
    echo "  Uptime: $uptime_info"
  fi

  # Disk space
  local disk_info=$(df -h / 2>/dev/null | awk 'NR==2 {print $4 " free of " $2}')
  if [ -n "$disk_info" ]; then
    echo "  Disk: $disk_info"
  fi

  # Memory usage (convert VM pages to gigabytes)
  local mem_info=$(vm_stat 2>/dev/null | awk '
    /Pages free/ {free=$3}
    /Pages active/ {active=$3}
    /Pages inactive/ {inactive=$3}
    /Pages speculative/ {spec=$3}
    /Pages wired/ {wired=$3}
    END {
      gsub(/\./, "", free); gsub(/\./, "", active); gsub(/\./, "", inactive); gsub(/\./, "", spec); gsub(/\./, "", wired)
      page_size = 2 * 2048
      bytes_per_gb = 1024 * 1024 * 1024
      used = (active + wired) * page_size / bytes_per_gb
      total = (free + active + inactive + spec + wired) * page_size / bytes_per_gb
      printf "%.1fGB used of %.1fGB", used, total
    }')
  if [ -n "$mem_info" ]; then
    echo "  Memory: $mem_info"
  fi

  # Battery status (for laptops)
  local battery_info=$(pmset -g batt 2>/dev/null | grep -o '[0-9]*%' | head -1)
  local charging_status=$(pmset -g batt 2>/dev/null | grep -o "'.*'" | tr -d "'")
  if [ -n "$battery_info" ]; then
    if [ -n "$charging_status" ]; then
      echo "  Battery: $battery_info ($charging_status)"
    else
      echo "  Battery: $battery_info"
    fi
  fi

  echo ""
}
