#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'lib/app/sections/command_not_found.sh'
Include "$PWD/spec/spec_helper.sh"
Before 'source_goodmorning'

Describe 'show_command_not_found function'
It 'is defined'
When call type show_command_not_found
The status should be success
The output should include "function"
End

It 'outputs section header when log file is missing'
XDG_DATA_HOME="/tmp/nonexistent-xdg-$$"
When call show_command_not_found
The output should include "Recent Commands Not Found"
End

It 'outputs no-log message when log file does not exist'
XDG_DATA_HOME="/tmp/nonexistent-xdg-$$"
When call show_command_not_found
The output should include "No command-not-found log yet"
End

It 'outputs section header when log has entries'
local log_dir
log_dir=$(mktemp -d)
mkdir -p "$log_dir/zsh"
printf 'zsh: command not found: gti\nzsh: command not found: gti\nzsh: command not found: sl\n' >"$log_dir/zsh/command-not-found.log"
XDG_DATA_HOME="$log_dir"
When call show_command_not_found
The output should include "Recent Commands Not Found"
End

It 'shows mistyped commands from log file'
local log_dir
log_dir=$(mktemp -d)
mkdir -p "$log_dir/zsh"
printf 'zsh: command not found: gti\nzsh: command not found: gti\nzsh: command not found: sl\n' >"$log_dir/zsh/command-not-found.log"
XDG_DATA_HOME="$log_dir"
When call show_command_not_found
The output should include "gti"
End

It 'outputs no-commands message when log file is empty'
local log_dir
log_dir=$(mktemp -d)
mkdir -p "$log_dir/zsh"
printf '' >"$log_dir/zsh/command-not-found.log"
XDG_DATA_HOME="$log_dir"
When call show_command_not_found
The output should include "No commands logged yet"
End
End
End
