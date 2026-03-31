#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'lib/app/sections/jira_tickets.sh'
Include "$PWD/spec/spec_helper.sh"
Before 'source_goodmorning'

Describe '_validate_jira_setup function'
It 'is defined'
When call type _validate_jira_setup
The status should be success
The output should include "function"
End

It 'returns 1 when JIRA_DOMAIN is empty'
JIRA_DOMAIN=""
JIRA_EMAIL="test@example.com"
JIRA_TOKEN_FILE="/tmp/fake-token"
When call _validate_jira_setup
The status should equal 1
End

It 'returns 1 when JIRA_EMAIL is empty'
JIRA_DOMAIN="test.atlassian.net"
JIRA_EMAIL=""
JIRA_TOKEN_FILE="/tmp/fake-token"
When call _validate_jira_setup
The status should equal 1
End

It 'returns 1 when JIRA_TOKEN_FILE is empty'
JIRA_DOMAIN="test.atlassian.net"
JIRA_EMAIL="test@example.com"
JIRA_TOKEN_FILE=""
When call _validate_jira_setup
The status should equal 1
End

It 'returns 1 when token file does not exist'
JIRA_DOMAIN="test.atlassian.net"
JIRA_EMAIL="test@example.com"
JIRA_TOKEN_FILE="/tmp/nonexistent-token-file-$$"
When call _validate_jira_setup
The status should equal 1
End

It 'returns 0 when all config is valid'
JIRA_DOMAIN="test.atlassian.net"
JIRA_EMAIL="test@example.com"
JIRA_TOKEN_FILE=$(mktemp)
echo "fake-token" >"$JIRA_TOKEN_FILE"
When call _validate_jira_setup
The status should equal 0
End
End

Describe '_read_jira_token function'
It 'is defined'
When call type _read_jira_token
The status should be success
The output should include "function"
End

It 'reads token from file and trims whitespace'
local token_file=$(mktemp)
printf '  my-secret-token  \n' >"$token_file"
JIRA_TOKEN_FILE="$token_file"
When call _read_jira_token
The output should equal "my-secret-token"
The status should be success
End

It 'returns 1 when token file is empty'
local token_file=$(mktemp)
printf '' >"$token_file"
JIRA_TOKEN_FILE="$token_file"
When call _read_jira_token
The status should equal 1
End
End

Describe '_build_jira_auth_header function'
It 'is defined'
When call type _build_jira_auth_header
The status should be success
The output should include "function"
End

It 'returns base64 encoded email:token'
JIRA_EMAIL="test@example.com"
local expected=$(printf 'test@example.com:fake-token' | base64)
When call _build_jira_auth_header "fake-token"
The output should equal "$expected"
End
End

Describe '_build_jira_jql function'
It 'is defined'
When call type _build_jira_jql
The status should be success
The output should include "function"
End

It 'returns JQL for assigned open tickets'
When call _build_jira_jql
The output should include "assignee = currentUser()"
The output should include "statusCategory != Done"
The output should include "ORDER BY"
End

It 'orders by status then updated'
When call _build_jira_jql
The output should include "ORDER BY status ASC, updated DESC"
End
End

Describe '_parse_jira_tickets function'
It 'is defined'
When call type _parse_jira_tickets
The status should be success
The output should include "function"
End

It 'extracts ticket key, summary, status, and category from API response'
local api_response='{"issues":[{"key":"SD-57","fields":{"summary":"Cart surcharge","status":{"name":"In Progress","statusCategory":{"name":"In Progress"}}}}]}'
When call _parse_jira_tickets "$api_response"
The output should include "SD-57"
The output should include "Cart surcharge"
The output should include "In Progress"
End

It 'returns empty for response with no issues'
local api_response='{"issues":[]}'
When call _parse_jira_tickets "$api_response"
The output should equal ""
End
End

Describe '_get_status_categories function'
It 'is defined'
When call type _get_status_categories
The status should be success
The output should include "function"
End

It 'returns unique status categories in display order'
local parsed_tickets='{"key":"SD-1","summary":"Task A","status":"Dev","category":"In Progress"}
{"key":"SD-2","summary":"Task B","status":"To Do","category":"To Do"}
{"key":"SD-3","summary":"Task C","status":"Review","category":"In Progress"}'
When call _get_status_categories "$parsed_tickets"
The line 1 should equal "In Progress"
The line 2 should equal "To Do"
End
End

Describe '_display_jira_ticket_group function'
It 'is defined'
When call type _display_jira_ticket_group
The status should be success
The output should include "function"
End

It 'displays category header with count'
local tickets='{"key":"SD-57","summary":"Cart surcharge","status":"In Progress","category":"In Progress"}
{"key":"SD-50","summary":"Payment validation","status":"In Progress","category":"In Progress"}'
JIRA_DOMAIN="test.atlassian.net"
When call _display_jira_ticket_group "In Progress" "$tickets"
The output should include "In Progress (2)"
End

It 'displays ticket key and summary'
local tickets='{"key":"SD-57","summary":"Cart surcharge","status":"In Progress","category":"In Progress"}'
JIRA_DOMAIN="test.atlassian.net"
When call _display_jira_ticket_group "In Progress" "$tickets"
The output should include "SD-57: Cart surcharge"
End

It 'displays ticket URL'
local tickets='{"key":"SD-57","summary":"Cart surcharge","status":"In Progress","category":"In Progress"}'
JIRA_DOMAIN="test.atlassian.net"
When call _display_jira_ticket_group "In Progress" "$tickets"
The output should include "https://test.atlassian.net/browse/SD-57"
End
End

Describe 'show_jira_tickets function'
It 'is defined'
When call type show_jira_tickets
The status should be success
The output should include "function"
End

It 'returns early when config is missing'
JIRA_DOMAIN=""
JIRA_EMAIL=""
JIRA_TOKEN_FILE=""
When call show_jira_tickets
The status should be success
The output should be present
End

It 'shows empty message when API returns no issues'
JIRA_DOMAIN="test.atlassian.net"
JIRA_EMAIL="test@example.com"
local token_file=$(mktemp)
echo "fake-token" >"$token_file"
JIRA_TOKEN_FILE="$token_file"

curl() { echo '{"issues":[],"isLast":true}'; }

When call show_jira_tickets
The output should include "No open Jira tickets assigned to you"
End

It 'displays tickets grouped by status when API returns data'
JIRA_DOMAIN="test.atlassian.net"
JIRA_EMAIL="test@example.com"
local token_file=$(mktemp)
echo "fake-token" >"$token_file"
JIRA_TOKEN_FILE="$token_file"

curl() {
  echo '{"issues":[{"key":"SD-57","fields":{"summary":"Cart surcharge","status":{"name":"In Progress","statusCategory":{"name":"In Progress"}}}},{"key":"SD-62","fields":{"summary":"Webhook columns","status":{"name":"To Do","statusCategory":{"name":"To Do"}}}}],"isLast":true}'
}

When call show_jira_tickets
The output should include "In Progress (1)"
The output should include "SD-57: Cart surcharge"
The output should include "To Do (1)"
The output should include "SD-62: Webhook columns"
End

It 'handles API errors gracefully'
JIRA_DOMAIN="test.atlassian.net"
JIRA_EMAIL="test@example.com"
local token_file=$(mktemp)
echo "fake-token" >"$token_file"
JIRA_TOKEN_FILE="$token_file"

curl() { return 1; }

When call show_jira_tickets
The output should include "Unable to fetch Jira tickets"
End
End
End
