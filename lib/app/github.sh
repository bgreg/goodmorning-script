#!/usr/bin/env zsh

###############################################################################
# GitHub Functions
#
# Displays GitHub PR and Issue review information:
# - Open PRs assigned to you with CI status, unresolved comments, merge conflicts
# - Open issues assigned to you
###############################################################################

_validate_github_setup() {
  if ! command_exists gh; then
    show_setup_message "Install GitHub CLI: brew install gh"
    echo ""
    return 1
  fi

  if ! gh auth status &>/dev/null; then
    show_setup_message "Authenticate: gh auth login"
    echo ""
    return 1
  fi

  return 0
}

_check_github_rate_limit() {
  local response_data="$1"

  if echo "$response_data" | grep -q "rate limit" 2>/dev/null; then
    echo_yellow "GitHub API rate limit exceeded"
    echo_gray "  → Wait a few minutes or check: gh api rate_limit"
    echo ""
    return 1
  fi

  return 0
}

_format_pr_ci_status() {
  local ci_state="$1"

  case "$ci_state" in
    SUCCESS) echo "✅" ;;
    PENDING) echo "⏳" ;;
    FAILURE|ERROR) echo "❌" ;;
    *) echo "❓" ;;
  esac
}

_format_pr_merge_status() {
  local mergeable="$1"

  case "$mergeable" in
    MERGEABLE) echo "" ;;
    CONFLICTING) echo " ⚠️  CONFLICTS" ;;
    UNKNOWN) echo " 🔄" ;;
    *) echo "" ;;
  esac
}

_display_pr_comments() {
  local pr_json="$1"
  local username="$2"
  local unresolved_count="$3"

  if [ "$unresolved_count" -gt 0 ]; then
    echo_yellow "    💬 ${unresolved_count} unresolved comment(s)"

    printf '%s' "$pr_json" | jq -r '.reviewThreads.nodes[] | select(.isResolved == false and .comments.nodes[0].author.login != "'"$username"'") | .comments.nodes[0].url' 2>> "$LOG_FILE" | head -3 | while read -r comment_url; do
      echo_gray "       → $comment_url"
    done
  fi
}

_display_single_pr() {
  local pr_json="$1"
  local username="$2"

  local pr_repo=$(printf '%s' "$pr_json" | jq -r '.repository.nameWithOwner')
  local pr_title=$(printf '%s' "$pr_json" | jq -r '.title')
  local pr_url=$(printf '%s' "$pr_json" | jq -r '.url')
  local pr_number=$(printf '%s' "$pr_json" | jq -r '.number')
  local mergeable=$(printf '%s' "$pr_json" | jq -r '.mergeable')
  local ci_state=$(printf '%s' "$pr_json" | jq -r '.commits.nodes[0].commit.statusCheckRollup.state // "UNKNOWN"')

  local unresolved_count=$(printf '%s' "$pr_json" | jq '[.reviewThreads.nodes[] | select(.isResolved == false and .comments.nodes[0].author.login != "'"$username"'")] | length')

  local ci_icon=$(_format_pr_ci_status "$ci_state")
  local merge_icon=$(_format_pr_merge_status "$mergeable")

  echo "  • ${pr_repo}#${pr_number}: ${pr_title}"
  echo "    ${ci_icon} CI${merge_icon}"

  _display_pr_comments "$pr_json" "$username" "$unresolved_count"

  echo "    🔗 $pr_url"
  echo ""
}

show_github_prs() {
  print_section "🔀 GitHub PR Review:" "yellow"

  _validate_github_setup || return 0

  local username
  username=$(gh api user --jq '.login' 2>> "$LOG_FILE")
  if [ -z "$username" ]; then
    echo "Unable to fetch GitHub username"
    echo ""
    return 0
  fi

  # Fetch PRs where user is author or assigned reviewer
  local pr_query='query { authored: search(query: "type:pr is:open author:@me", type: ISSUE, first: 25) { nodes { ... on PullRequest { number title url repository { nameWithOwner } mergeable commits(last: 1) { nodes { commit { statusCheckRollup { state } } } } reviewThreads(first: 50) { nodes { isResolved comments(first: 1) { nodes { author { login } url } } } } } } } reviewRequested: search(query: "type:pr is:open review-requested:@me", type: ISSUE, first: 25) { nodes { ... on PullRequest { number title url repository { nameWithOwner } } } } }'

  local pr_data
  pr_data=$(fetch_with_spinner "Fetching PRs..." gh api graphql -f query="$pr_query" 2>> "$LOG_FILE")

  if [ $? -ne 0 ] || [ -z "$pr_data" ]; then
    _check_github_rate_limit "$pr_data" || echo "Unable to fetch PR data"
    echo ""
    return 0
  fi

  local authored_count
  authored_count=$(printf '%s' "$pr_data" | jq '.data.authored.nodes | length' 2>> "$LOG_FILE")
  local review_requested_count
  review_requested_count=$(printf '%s' "$pr_data" | jq '.data.reviewRequested.nodes | length' 2>> "$LOG_FILE")

  if [ "$authored_count" -eq 0 ] && [ "$review_requested_count" -eq 0 ]; then
    echo "No open PRs requiring attention"
    echo ""
    return 0
  fi

  # Display authored PRs with details
  if [ "$authored_count" -gt 0 ]; then
    local max_prs="${MAX_GITHUB_PRS:-5}"
    if [ "$authored_count" -gt "$max_prs" ]; then
      echo_cyan "Your Open PRs (showing $max_prs of $authored_count):"
      echo_gray "  → Adjust GOODMORNING_MAX_GITHUB_PRS in config to show more"
    else
      echo_cyan "Your Open PRs ($authored_count):"
    fi
    echo ""

    printf '%s' "$pr_data" | jq -r '.data.authored.nodes[:'"$max_prs"'] | .[] | @json' 2>> "$LOG_FILE" | while read -r pr_json; do
      _display_single_pr "$pr_json" "$username"
    done
  fi

  # Display PRs awaiting your review
  if [ "$review_requested_count" -gt 0 ]; then
    local max_prs="${MAX_GITHUB_PRS:-5}"
    if [ "$review_requested_count" -gt "$max_prs" ]; then
      echo_cyan "Awaiting Your Review (showing $max_prs of $review_requested_count):"
      echo_gray "  → Adjust GOODMORNING_MAX_GITHUB_PRS in config to show more"
    else
      echo_cyan "Awaiting Your Review ($review_requested_count):"
    fi
    echo ""

    printf '%s' "$pr_data" | jq -r '.data.reviewRequested.nodes[:'"$max_prs"'] | .[] | "  • \(.repository.nameWithOwner)#\(.number): \(.title)\n    🔗 \(.url)\n"' 2>> "$LOG_FILE"
    echo ""
  fi
}

_display_single_issue() {
  local issue_json="$1"

  local issue_repo=$(printf '%s' "$issue_json" | jq -r '.repository.nameWithOwner')
  local issue_title=$(printf '%s' "$issue_json" | jq -r '.title')
  local issue_url=$(printf '%s' "$issue_json" | jq -r '.url')
  local issue_number=$(printf '%s' "$issue_json" | jq -r '.number')
  local comment_count=$(printf '%s' "$issue_json" | jq -r '.comments.totalCount')
  local labels=$(printf '%s' "$issue_json" | jq -r '[.labels.nodes[].name] | join(", ")')

  echo "  • ${issue_repo}#${issue_number}: ${issue_title}"

  if [ -n "$labels" ] && [ "$labels" != "" ]; then
    echo_gray "    🏷️  $labels"
  fi

  if [ "$comment_count" -gt 0 ]; then
    echo_gray "    💬 $comment_count comment(s)"
  fi

  echo "    🔗 $issue_url"
  echo ""
}

show_github_issues() {
  print_section "📋 GitHub Issues:" "yellow"

  _validate_github_setup || return 0

  # Fetch issues assigned to user
  local issues_query='query { search(query: "type:issue is:open assignee:@me", type: ISSUE, first: 25) { issueCount nodes { ... on Issue { number title url repository { nameWithOwner } labels(first: 5) { nodes { name } } comments { totalCount } createdAt } } } }'

  local issues_data
  issues_data=$(fetch_with_spinner "Fetching issues..." gh api graphql -f query="$issues_query" 2>> "$LOG_FILE")

  if [ $? -ne 0 ] || [ -z "$issues_data" ]; then
    _check_github_rate_limit "$issues_data" || echo "Unable to fetch issues"
    echo ""
    return 0
  fi

  local issue_count
  issue_count=$(printf '%s' "$issues_data" | jq '.data.search.issueCount' 2>> "$LOG_FILE")

  if [ "$issue_count" -eq 0 ]; then
    echo "No open issues assigned to you"
    echo ""
    return 0
  fi

  local max_issues="${MAX_GITHUB_ISSUES:-5}"
  if [ "$issue_count" -gt "$max_issues" ]; then
    echo "You have ${issue_count} open issue(s) (showing $max_issues):"
    echo_gray "  → Adjust GOODMORNING_MAX_GITHUB_ISSUES in config to show more"
  else
    echo "You have ${issue_count} open issue(s) assigned:"
  fi
  echo ""

  printf '%s' "$issues_data" | jq -r '.data.search.nodes[:'"$max_issues"'] | .[] | @json' 2>> "$LOG_FILE" | while read -r issue_json; do
    _display_single_issue "$issue_json"
  done
}
