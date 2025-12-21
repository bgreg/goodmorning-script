#!/usr/bin/env zsh
#shellspec shell=zsh

###############################################################################
# Version Information Tests
#
# Tests for lib/app/versions.sh
###############################################################################

Describe 'lib/app/versions.sh'
  Include "$PWD/spec/spec_helper.sh"
  Before 'source_goodmorning'

  Describe '_fetch_github_version function'
    It 'is defined'
      When call type _fetch_github_version
      The status should be success
      The output should include "function"
    End
  End

  Describe '_fetch_go_version function'
    It 'is defined'
      When call type _fetch_go_version
      The status should be success
      The output should include "function"
    End
  End

  Describe '_fetch_python_version function'
    It 'is defined'
      When call type _fetch_python_version
      The status should be success
      The output should include "function"
    End
  End

  Describe '_fetch_node_version function'
    It 'is defined'
      When call type _fetch_node_version
      The status should be success
      The output should include "function"
    End
  End

  Describe 'get_tech_versions function'
    It 'is defined'
      When call type get_tech_versions
      The status should be success
      The output should include "function"
    End

    It 'returns pipe-delimited version strings'
      # Mock curl to avoid network calls
      curl() { echo '{"tag_name": "v1.0.0"}'; }
      When call get_tech_versions
      The output should include "|"
    End
  End

  Describe 'show_tech_versions function'
    It 'is defined'
      When call type show_tech_versions
      The status should be success
      The output should include "function"
    End

    It 'returns early when GOODMORNING_FORCE_OFFLINE is set'
      GOODMORNING_FORCE_OFFLINE=1
      When call show_tech_versions
      The status should be success
      The output should equal ""
    End
  End
End
