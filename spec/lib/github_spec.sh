#!/usr/bin/env zsh
#shellspec shell=zsh

###############################################################################
# GitHub Functions Tests
#
# Tests for lib/app/github.sh
###############################################################################

Describe 'lib/app/github.sh'
  Include "$PWD/spec/spec_helper.sh"
  Before 'source_goodmorning'

  Describe '_validate_github_setup function'
    It 'is defined'
      When call type _validate_github_setup
      The status should be success
      The output should include "function"
    End

    It 'returns 1 when gh CLI is not installed'
      command_exists() { return 1; }
      When call _validate_github_setup
      The status should equal 1
    End

    It 'returns 0 when gh is installed and authenticated'
      command_exists() { return 0; }
      gh() { return 0; }
      When call _validate_github_setup
      The status should equal 0
    End
  End

  Describe '_check_github_rate_limit function'
    It 'is defined'
      When call type _check_github_rate_limit
      The status should be success
      The output should include "function"
    End

    It 'returns 1 when rate limit message is present'
      When call _check_github_rate_limit "API rate limit exceeded"
      The status should equal 1
    End

    It 'returns 0 when no rate limit message'
      When call _check_github_rate_limit '{"data": {"user": "test"}}'
      The status should equal 0
    End
  End

  Describe '_format_pr_ci_status function'
    It 'is defined'
      When call type _format_pr_ci_status
      The status should be success
      The output should include "function"
    End

    It 'returns green check for SUCCESS'
      When call _format_pr_ci_status "SUCCESS"
      The output should equal "✅"
    End

    It 'returns hourglass for PENDING'
      When call _format_pr_ci_status "PENDING"
      The output should equal "⏳"
    End

    It 'returns red X for FAILURE'
      When call _format_pr_ci_status "FAILURE"
      The output should equal "❌"
    End

    It 'returns red X for ERROR'
      When call _format_pr_ci_status "ERROR"
      The output should equal "❌"
    End

    It 'returns question mark for unknown states'
      When call _format_pr_ci_status "UNKNOWN"
      The output should equal "❓"
    End

    It 'returns question mark for empty input'
      When call _format_pr_ci_status ""
      The output should equal "❓"
    End
  End

  Describe '_format_pr_merge_status function'
    It 'is defined'
      When call type _format_pr_merge_status
      The status should be success
      The output should include "function"
    End

    It 'returns conflict warning for CONFLICTING'
      When call _format_pr_merge_status "CONFLICTING"
      The output should include "CONFLICTS"
    End

    It 'returns sync icon for UNKNOWN'
      When call _format_pr_merge_status "UNKNOWN"
      The output should include "🔄"
    End
  End

  Describe '_build_authored_and_review_requested_prs_query function'
    It 'is defined'
      When call type _build_authored_and_review_requested_prs_query
      The status should be success
      The output should include "function"
    End

    It 'returns a GraphQL query string'
      When call _build_authored_and_review_requested_prs_query
      The output should include "query"
      The output should include "authored"
      The output should include "reviewRequested"
      The output should include "type:pr"
      The output should include "is:open"
    End

    It 'includes PR fields in query'
      When call _build_authored_and_review_requested_prs_query
      The output should include "number"
      The output should include "title"
      The output should include "url"
      The output should include "mergeable"
      The output should include "statusCheckRollup"
    End
  End

  Describe '_build_assigned_issues_query function'
    It 'is defined'
      When call type _build_assigned_issues_query
      The status should be success
      The output should include "function"
    End

    It 'returns a GraphQL query for issues'
      When call _build_assigned_issues_query
      The output should include "query"
      The output should include "type:issue"
      The output should include "is:open"
      The output should include "assignee:@me"
    End

    It 'includes issue fields in query'
      When call _build_assigned_issues_query
      The output should include "issueCount"
      The output should include "number"
      The output should include "title"
      The output should include "labels"
      The output should include "comments"
    End
  End

  Describe '_display_single_pr function'
    setup_pr_json() {
      PR_JSON='{"repository":{"nameWithOwner":"owner/repo"},"title":"Test PR","url":"https://github.com/owner/repo/pull/1","number":1,"mergeable":"MERGEABLE","commits":{"nodes":[{"commit":{"statusCheckRollup":{"state":"SUCCESS"}}}]},"reviewThreads":{"nodes":[]}}'
    }

    It 'is defined'
      When call type _display_single_pr
      The status should be success
      The output should include "function"
    End

    It 'displays PR information'
      setup_pr_json
      When call _display_single_pr "$PR_JSON" "testuser"
      The output should include "owner/repo#1"
      The output should include "Test PR"
      The output should include "https://github.com/owner/repo/pull/1"
    End

    It 'displays CI status icon'
      setup_pr_json
      When call _display_single_pr "$PR_JSON" "testuser"
      The output should include "✅"
    End
  End

  Describe '_display_single_issue function'
    setup_issue_json() {
      ISSUE_JSON='{"repository":{"nameWithOwner":"owner/repo"},"title":"Test Issue","url":"https://github.com/owner/repo/issues/42","number":42,"labels":{"nodes":[{"name":"bug"}]},"comments":{"totalCount":3}}'
    }

    It 'is defined'
      When call type _display_single_issue
      The status should be success
      The output should include "function"
    End

    It 'displays issue information'
      setup_issue_json
      When call _display_single_issue "$ISSUE_JSON"
      The output should include "owner/repo#42"
      The output should include "Test Issue"
      The output should include "https://github.com/owner/repo/issues/42"
    End

    It 'displays labels when present'
      setup_issue_json
      When call _display_single_issue "$ISSUE_JSON"
      The output should include "bug"
    End

    It 'displays comment count when non-zero'
      setup_issue_json
      When call _display_single_issue "$ISSUE_JSON"
      The output should include "3 comment"
    End
  End

  Describe 'show_github_prs function'
    It 'is defined'
      When call type show_github_prs
      The status should be success
      The output should include "function"
    End

    It 'returns early when gh CLI not available'
      command_exists() { [[ "$1" != "gh" ]]; }
      When call show_github_prs
      The status should be success
    End
  End

  Describe 'show_github_issues function'
    It 'is defined'
      When call type show_github_issues
      The status should be success
      The output should include "function"
    End

    It 'returns early when gh CLI not available'
      command_exists() { [[ "$1" != "gh" ]]; }
      When call show_github_issues
      The status should be success
    End
  End
End
