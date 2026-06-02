#!/usr/bin/env zsh

###############################################################################
# System Information Section
#
# Displays macOS system information including version, uptime, disk, memory, and battery
###############################################################################

register_section "system_info" --tools "sw_vers" "uptime" "df" "awk"

show_system_info() {
  print_section "💻 System Information:" "yellow"

  # macOS version with update check
  local macos_version=$(sw_vers -productVersion 2>> "$LOG_FILE")
  local macos_build=$(sw_vers -buildVersion 2>> "$LOG_FILE")
  if [ -n "$macos_version" ]; then
    # Check for available macOS updates (uses cached data, fast)
    # Filter out beta/developer releases - only show stable updates
    local macos_updates=$(softwareupdate -l 2>/dev/null | grep -i "macOS" | grep -iv "beta" | head -1)
    if [ -n "$macos_updates" ]; then
      local available_version=$(echo "$macos_updates" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
      echo "  macOS: $macos_version ($macos_build)"
      echo_yellow "  ⚠️  Update available: macOS ${available_version:-update}"
    else
      echo "  macOS: $macos_version ($macos_build) ✓"
    fi
  fi

  # Safari version
  local safari_plist="/Applications/Safari.app/Contents/Info.plist"
  local safari_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$safari_plist" 2>> "$LOG_FILE")
  if [ -n "$safari_version" ]; then
    echo "  Safari: $safari_version"
  fi

  # Uptime (time since last reboot)
  local uptime_info=$(uptime | sed -E 's/.*up //; s/, [0-9]+ user.*//; s/,  +/, /; s/^ +//')
  if [ -n "$uptime_info" ]; then
    echo "  Uptime: $uptime_info"
  fi

  # Disk space
  local disk_info=$(df -h / 2>> "$LOG_FILE" | awk 'NR==2 {print $4 " free of " $2}' | sed 's/Gi/GB/g; s/Ti/TB/g; s/Mi/MB/g')
  if [ -n "$disk_info" ]; then
    echo "  Disk: $disk_info"
  fi

  # Memory usage: active + wired + compressed, matching Activity Monitor "Memory Used"
  local page_size=$(sysctl -n hw.pagesize 2>> "$LOG_FILE")
  local total_bytes=$(sysctl -n hw.memsize 2>> "$LOG_FILE")
  local mem_info=$(vm_stat 2>> "$LOG_FILE" | awk -v page_size="$page_size" -v total_bytes="$total_bytes" '
    /Pages active/                 { active=$3 }
    /Pages wired down/             { wired=$4 }
    /Pages occupied by compressor/ { compressed=$5 }
    END {
      gsub(/\./, "", active); gsub(/\./, "", wired); gsub(/\./, "", compressed)
      bytes_per_gb = 1024 * 1024 * 1024
      used = (active + wired + compressed) * page_size / bytes_per_gb
      total = total_bytes / bytes_per_gb
      printf "%.1fGB used of %.1fGB", used, total
    }')
  if [ -n "$mem_info" ]; then
    echo "  Memory: $mem_info"
  fi

  # Battery status (for laptops)
  local battery_info=$(pmset -g batt 2>> "$LOG_FILE" | grep -o '[0-9]*%' | head -1)
  local charging_status=$(pmset -g batt 2>> "$LOG_FILE" | grep -Eo '[0-9]+%; [a-zA-Z ]+' | head -1 | sed -E 's/^[0-9]+%; //')
  if [ -n "$battery_info" ]; then
    if [ -n "$charging_status" ]; then
      echo "  Battery: $battery_info ($charging_status)"
    else
      echo "  Battery: $battery_info"
    fi
  fi

  show_new_line
}
