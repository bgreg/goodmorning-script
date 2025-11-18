#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'lib/updates.sh - Background Updates'
  Before 'source_goodmorning'

  Describe 'start_background_updates function'
    It 'is defined'
      When call type start_background_updates
      The status should be success
      The output should not be blank
    End

    It 'tracks background PIDs'
      When call grep 'BACKGROUND_PIDS' "$PROJECT_ROOT/lib/updates.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe 'Text-to-speech integration'
    It 'respects GOODMORNING_ENABLE_TTS=false by default'
      unset GOODMORNING_ENABLE_TTS
      When call grep 'GOODMORNING_ENABLE_TTS.*false' "$PROJECT_ROOT/lib/updates.sh"
      The status should be success
      The output should not be blank
    End

    It 'checks GOODMORNING_ENABLE_TTS before calling say'
      When call grep -A 2 'GOODMORNING_ENABLE_TTS.*true' "$PROJECT_ROOT/lib/updates.sh"
      The output should include "say"
    End

    It 'conditionally calls say command'
      When call grep 'if.*GOODMORNING_ENABLE_TTS' "$PROJECT_ROOT/lib/updates.sh"
      The status should be success
      The output should include "GOODMORNING_ENABLE_TTS"
    End
  End

  Describe '_goodmorning_updates function'
    It 'is defined'
      When call type _goodmorning_updates
      The status should be success
      The output should not be blank
    End

    It 'creates temp log file'
      When call grep 'mktemp.*UPDATES_LOG_PATTERN' "$PROJECT_ROOT/lib/updates.sh"
      The status should be success
      The output should not be blank
    End

    It 'tracks temp files'
      When call grep 'TEMP_FILES+=.*log_file' "$PROJECT_ROOT/lib/updates.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe 'macOS notification'
    It 'uses extracted AppleScript for notifications'
      When call grep 'apple_script/show_notification.scpt' "$PROJECT_ROOT/lib/updates.sh"
      The status should be success
      The output should not be blank
    End

    It 'passes notification message and title'
      When call grep -A 2 'show_notification.scpt' "$PROJECT_ROOT/lib/updates.sh"
      The output should include "Backup and system updates complete"
      The output should include "Good Morning Complete"
    End
  End

  Describe '_run_backup function'
    It 'is defined'
      When call type _run_backup
      The status should be success
      The output should include "function"
    End

    It 'checks for BACKUP_SCRIPT variable'
      When call grep 'BACKUP_SCRIPT' "$PROJECT_ROOT/lib/updates.sh"
      The status should be success
      The output should not be blank
    End

    It 'validates backup script exists'
      When call grep '\[ -f.*BACKUP_SCRIPT' "$PROJECT_ROOT/lib/updates.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe '_update_homebrew function'
    It 'is defined'
      When call type _update_homebrew
      The status should be success
      The output should not be blank
    End

    It 'runs brew update'
      When call grep 'brew update' "$PROJECT_ROOT/lib/updates.sh"
      The status should be success
      The output should not be blank
    End

    It 'runs brew upgrade'
      When call grep 'brew upgrade' "$PROJECT_ROOT/lib/updates.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe '_update_claude_code function'
    It 'is defined'
      When call type _update_claude_code
      The status should be success
      The output should not be blank
    End

    It 'checks if claude command exists'
      When call grep 'command_exists claude' "$PROJECT_ROOT/lib/updates.sh"
      The status should be success
      The output should not be blank
    End

    It 'updates npm package'
      When call grep 'npm update.*claude-code' "$PROJECT_ROOT/lib/updates.sh"
      The status should be success
      The output should not be blank
    End
  End
End
