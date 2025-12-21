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
  End
End
