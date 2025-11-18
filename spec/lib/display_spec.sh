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

  Describe 'show_email function'
    It 'is defined'
      When call type show_email
      The status should be success
      The output should not be blank
    End

    It 'uses extracted AppleScript for Mail.app check'
      When call grep 'apple_script/check_mail_running.scpt' "$PROJECT_ROOT/lib/display.sh"
      The status should be success
      The output should not be blank
    End

    It 'uses extracted AppleScript for email count'
      When call grep 'apple_script/count_unread_emails.scpt' "$PROJECT_ROOT/lib/display.sh"
      The status should be success
      The output should not be blank
    End

    It 'uses extracted AppleScript for email list'
      When call grep 'apple_script/get_recent_emails.scpt' "$PROJECT_ROOT/lib/display.sh"
      The status should be success
      The output should not be blank
    End

    It 'validates email count is numeric'
      When call grep '\[\[.*email_count.*\^\[0-9\]' "$PROJECT_ROOT/lib/display.sh"
      The status should be success
      The output should not be blank
    End

    It 'respects MAX_EMAILS limit'
      When call grep 'MAX_EMAILS' "$PROJECT_ROOT/lib/display.sh"
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
End
