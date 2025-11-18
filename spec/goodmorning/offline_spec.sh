#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'goodmorning.sh - Offline Mode'
  Describe 'Offline mode implementation'
    It 'GOODMORNING_FORCE_OFFLINE environment variable is documented'
      When call grep -q 'GOODMORNING_FORCE_OFFLINE' ./README.md
      The status should be success
    End

    It 'offline mode functionality is documented'
      When call grep -q 'offline' ./README.md
      The status should be success
    End
  End
End
