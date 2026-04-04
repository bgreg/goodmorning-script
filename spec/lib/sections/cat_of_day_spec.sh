#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'lib/app/sections/cat_of_day.sh'
Include "$PWD/spec/spec_helper.sh"
Before 'source_goodmorning'

Describe 'fetch_cat function'
It 'is defined'
When call type fetch_cat
The status should be success
The output should include "function"
End

It 'returns cat JSON object from valid API response'
fetch_url() {
  printf '%s' '[{"id":"test123","url":"https://cdn2.thecatapi.com/images/test123.jpg","width":800,"height":600}]'
}
sleep() { :; }
When call fetch_cat
The status should be success
The output should include "cdn2.thecatapi.com"
End

It 'returns failure when API response is empty'
fetch_url() { printf ''; }
sleep() { :; }
When call fetch_cat
The status should equal 1
End
End

Describe 'show_cat_of_day function'
It 'is defined'
When call type show_cat_of_day
The status should be success
The output should include "function"
End

It 'outputs section header'
fetch_with_spinner() { printf ''; }
show_setup_message() { :; }
When call show_cat_of_day
The output should include "Cat of the Day"
End

It 'shows warning when no data is returned'
fetch_with_spinner() { printf ''; }
show_setup_message() { echo "$*"; }
When call show_cat_of_day
The output should include "Could not fetch cat image"
End

It 'shows image URL when data is returned'
fetch_with_spinner() {
  printf '{"id":"test123","url":"https://cdn2.thecatapi.com/images/test123.jpg","width":800,"height":600}'
}
iterm_can_display_images() { return 1; }
download_image() { :; }
When call show_cat_of_day
The output should include "cdn2.thecatapi.com"
End
End
End
