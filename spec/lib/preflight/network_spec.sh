#!/usr/bin/env zsh

Describe 'lib/app/preflight/network.sh - Network Checks'
  Include lib/app/preflight/network.sh

  Describe 'check_internet function'
    It 'is defined'
      When call type check_internet
      The status should be success
    End

    It 'returns without blocking'
      # Should complete quickly
      When call check_internet
      The status should be success
    End

    It 'sets NETWORK_ONLINE variable'
      check_internet
      The variable NETWORK_ONLINE should be defined
    End
  End

  Describe 'is_online function'
    It 'is defined'
      When call type is_online
      The status should be success
    End

    It 'returns boolean status'
      NETWORK_ONLINE="true"
      When call is_online
      The status should be success
    End

    It 'returns false when offline'
      NETWORK_ONLINE="false"
      When call is_online
      The status should be failure
    End
  End

  Describe 'skip_if_offline function'
    It 'is defined'
      When call type skip_if_offline
      The status should be success
    End

    It 'skips when offline'
      NETWORK_ONLINE="false"
      When call skip_if_offline
      The status should be success
    End
  End
End
