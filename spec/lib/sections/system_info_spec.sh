#!/usr/bin/env zsh
#shellspec shell=zsh

###############################################################################
# System Info Tests
#
# Tests for lib/app/sections/system_info.sh
###############################################################################

Describe 'lib/app/sections/system_info.sh'
  Include "$PWD/spec/spec_helper.sh"
  Before 'source_goodmorning'

  Describe 'show_system_info function'
    It 'is defined'
      When call type show_system_info
      The status should be success
      The output should include "function"
    End

    It 'displays system information'
      When call show_system_info
      The output should be present
    End

    It 'includes macOS version info'
      When call show_system_info
      The output should include "macOS"
    End

    It 'includes disk information'
      When call show_system_info
      The output should include "Disk"
    End

    It 'does not show beta releases as available updates'
      # Mock softwareupdate to return a beta release
      softwareupdate() {
        echo "Software Update Tool"
        echo ""
        echo "* Label: macOS Tahoe 26.2 Developer Beta"
        echo "        Title: macOS Tahoe 26.2 Developer Beta, Version: 26.2, Size: 1234KB, Recommended: YES, Action: restart"
      }

      When call show_system_info
      The output should not include "Update available"
    End

    It 'reports memory used and total from sysctl and vm_stat'
      sysctl() { case "$2" in hw.pagesize) echo 16384 ;; hw.memsize) echo 17179869184 ;; esac; }
      vm_stat() {
        echo "Pages active:                                  393216."
        echo "Pages wired down:                              65536."
        echo "Pages occupied by compressor:                  65536."
      }
      softwareupdate() { :; }
      When call show_system_info
      The output should include "Memory: 8.0GB used of 16.0GB"
    End

    It 'does not duplicate the word macOS'
      sw_vers() { case "$1" in -productName) echo "macOS" ;; -productVersion) echo "26.5" ;; -buildVersion) echo "25F71" ;; esac; }
      softwareupdate() { :; }
      When call show_system_info
      The output should include "macOS: 26.5 (25F71)"
      The output should not include "macOS macOS"
    End

    It 'shows the battery charge state, not the power source'
      pmset() {
        echo "Now drawing from 'AC Power'"
        printf ' -InternalBattery-0 (id=36765795)\t100%%; charged; 0:00 remaining present: true\n'
      }
      softwareupdate() { :; }
      When call show_system_info
      The output should include "Battery: 100% (charged)"
      The output should not include "(AC Power)"
    End

    It 'shows disk sizes with GB suffix'
      df() {
        echo "Filesystem      Size   Used  Avail Capacity iused ifree %iused  Mounted on"
        echo "/dev/disk3s1s1  926Gi  12Gi  48Gi   20%     459k  500M  0%      /"
      }
      softwareupdate() { :; }
      When call show_system_info
      The output should include "Disk: 48GB free of 926GB"
      The output should not include "Gi"
    End

    It 'includes hours and minutes in uptime'
      uptime() { echo "19:03  up 18 days,  1:29, 5 users, load averages: 31.68 33.51 25.69"; }
      softwareupdate() { :; }
      When call show_system_info
      The output should include "Uptime: 18 days, 1:29"
    End
  End
End
