#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'Test Infrastructure - Mocking'
  Describe 'open command mock'
    It 'prevents actual URL opening'
      # Ensure the mock is active
      When call open "https://example.com"
      The status should be success
      The stderr should include "[MOCK] Prevented opening URL: https://example.com"
    End

    It 'logs file URLs'
      When call open "file:///etc/passwd"
      The status should be success
      The stderr should include "[MOCK] Prevented opening URL: file:///etc/passwd"
    End

    It 'does not invoke system open command'
      # Verify that open is a function, not the system command
      When call type open
      The output should include "function"
    End
  End

  Describe 'say command mock'
    It 'prevents actual speech output'
      When call say "test message"
      The status should be success
      The stderr should include "[MOCK] Would say: test message"
    End

    It 'does not invoke system say command'
      # Verify that say is a function, not the system command
      When call type say
      The output should include "function"
    End
  End
End
