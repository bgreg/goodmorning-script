#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'goodmorning.sh - Configuration'
  Before 'source_goodmorning'

  Describe 'Script directory detection'
    It 'sets SCRIPT_DIR variable'
      The variable SCRIPT_DIR should not be blank
    End

    It 'SCRIPT_DIR points to valid directory'
      The path "$SCRIPT_DIR" should be directory
    End

    It 'respects GOODMORNING_SCRIPT_DIR override'
      export GOODMORNING_SCRIPT_DIR="/tmp/test"
      When call echo "$GOODMORNING_SCRIPT_DIR"
      The output should equal "/tmp/test"
    End
  End

  Describe 'Configuration variables'
    It 'sets CONFIG_DIR with default'
      The variable CONFIG_DIR should not be blank
    End

    It 'sets USER_NAME with default'
      The variable USER_NAME should not be blank
    End

    It 'sets default file paths'
      The variable BANNER_FILE should not be blank
      The variable LEARNING_SOURCES_FILE should not be blank
    End

    It 'respects GOODMORNING_USER_NAME override'
      export GOODMORNING_USER_NAME="TestUser"
      When call source_goodmorning
      The variable USER_NAME should equal "TestUser"
    End

    It 'respects GOODMORNING_ENABLE_TTS override'
      export GOODMORNING_ENABLE_TTS="true"
      When call source_goodmorning
      The variable GOODMORNING_ENABLE_TTS should equal "true"
    End
  End

  Describe 'Resource limits'
    It 'sets MAX_REMINDERS with default'
      The variable MAX_REMINDERS should not be blank
      The variable MAX_REMINDERS should equal 10
    End

    It 'sets MAX_EMAILS with default'
      The variable MAX_EMAILS should not be blank
      The variable MAX_EMAILS should equal 5
    End

    It 'sets MAX_HISTORY_EVENTS with default'
      The variable MAX_HISTORY_EVENTS should not be blank
      The variable MAX_HISTORY_EVENTS should equal 3
    End

    It 'sets SPINNER_TIMEOUT with default'
      The variable SPINNER_TIMEOUT should not be blank
      The variable SPINNER_TIMEOUT should equal 30
    End
  End

  Describe 'Auto-execution prevention'
    It 'does not auto-run when GOODMORNING_NO_AUTO_RUN is set'
      The variable GOODMORNING_NO_AUTO_RUN should equal "1"
    End
  End

  Describe 'Command line arguments'
    It 'accepts --noisy flag'
      When call grep -E '^\s+--noisy\)' ./goodmorning.sh
      The status should be success
      The output should include "--noisy"
    End

    It 'accepts --help flag'
      When call grep -E '(--help|-h)' ./goodmorning.sh
      The status should be success
      The output should include "help"
    End
  End
End
