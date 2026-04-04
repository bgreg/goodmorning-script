#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'lib/app/sections/alias_suggestions.sh'
Include "$PWD/spec/spec_helper.sh"
Before 'source_goodmorning'

Describe 'show_alias_suggestions function'
It 'is defined'
When call type show_alias_suggestions
The status should be success
The output should include "function"
End

It 'outputs section header'
local hist_file=$(mktemp)
HISTFILE="$hist_file"
When call show_alias_suggestions
The output should include "Alias Suggestions"
End

It 'outputs history file not found when HISTFILE does not exist'
HISTFILE="/tmp/nonexistent-history-file-$$"
When call show_alias_suggestions
The output should include "History file not found"
End

It 'outputs section header even when HISTFILE does not exist'
HISTFILE="/tmp/nonexistent-history-file-$$"
When call show_alias_suggestions
The output should include "Alias Suggestions"
End

It 'outputs no frequent commands message for empty history file'
local hist_file=$(mktemp)
HISTFILE="$hist_file"
When call show_alias_suggestions
The output should include "No frequently used long commands found"
End

It 'shows frequent long commands from history'
local hist_file=$(mktemp)
printf 'docker compose up --build --force-recreate\n%.0s' {1..5} >>"$hist_file"
HISTFILE="$hist_file"
When call show_alias_suggestions
The output should include "docker compose up"
End

It 'does not show commands shorter than 10 characters'
local hist_file=$(mktemp)
printf 'ls\n%.0s' {1..5} >>"$hist_file"
HISTFILE="$hist_file"
When call show_alias_suggestions
The output should include "No frequently used long commands found"
End
End
End
