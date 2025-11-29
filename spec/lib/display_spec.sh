#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'lib/display.sh - Display Functions'
  Before 'source_goodmorning'

  Describe 'show_banner function'
    It 'is defined'
      When call type show_banner
      The status should be success
      The output should not be blank
    End

    It 'checks for BANNER_FILE'
      When call grep 'BANNER_FILE' "$PROJECT_ROOT/lib/display.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe 'show_reminders function'
    It 'is defined'
      When call type show_reminders
      The status should be success
      The output should not be blank
    End

    It 'uses extracted AppleScript for reminder count'
      When call grep 'apple_script/count_reminders.scpt' "$PROJECT_ROOT/lib/display.sh"
      The status should be success
      The output should not be blank
    End

    It 'validates reminder count is numeric'
      When call grep '\[\[.*reminder_count.*\^\[0-9\]' "$PROJECT_ROOT/lib/display.sh"
      The status should be success
      The output should not be blank
    End

    It 'respects MAX_REMINDERS limit'
      When call grep 'MAX_REMINDERS' "$PROJECT_ROOT/lib/display.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe 'show_weather function'
    It 'is defined'
      When call type show_weather
      The status should be success
      The output should not be blank
    End
  End

  Describe 'show_history function'
    It 'is defined'
      When call type show_history
      The status should be success
      The output should not be blank
    End

    It 'respects MAX_HISTORY_EVENTS limit'
      When call grep 'MAX_HISTORY_EVENTS' "$PROJECT_ROOT/lib/display.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe 'show_calendar function'
    It 'is defined'
      When call type show_calendar
      The status should be success
      The output should not be blank
    End

    It 'supports icalBuddy integration'
      When call grep 'icalBuddy' "$PROJECT_ROOT/lib/display.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe 'show_learning_tips function'
    It 'is defined'
      When call type show_learning_tips
      The status should be success
      The output should not be blank
    End
  End

  Describe 'show_alias_suggestions function'
    It 'is defined'
      When call type show_alias_suggestions
      The status should be success
      The output should not be blank
    End

    It 'reads from shell history'
      When call grep 'HISTFILE' "$PROJECT_ROOT/lib/display.sh"
      The status should be success
      The output should not be blank
    End

    It 'checks for existing aliases'
      When call grep 'alias.*grep' "$PROJECT_ROOT/lib/display.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe 'show_common_typos function'
    It 'is defined'
      When call type show_common_typos
      The status should be success
      The output should not be blank
    End

    It 'has typo corrections mapping'
      When call grep 'typo_corrections' "$PROJECT_ROOT/lib/display.sh"
      The status should be success
      The output should not be blank
    End

    It 'includes common git typo'
      When call grep '\[gti\]="git"' "$PROJECT_ROOT/lib/display.sh"
      The status should be success
      The output should not be blank
    End
  End

  Describe 'show_cat_of_day function'
    It 'is defined'
      When call type show_cat_of_day
      The status should be success
      The output should not be blank
    End

    It 'uses Cat API'
      When call grep 'thecatapi.com' "$PROJECT_ROOT/lib/daily_content.sh"
      The status should be success
      The output should not be blank
    End

    It 'supports iTerm2 image display'
      When call grep 'imgcat\|1337;File=' "$PROJECT_ROOT/lib/daily_content.sh"
      The status should be success
      The output should not be blank
    End
  End
End
