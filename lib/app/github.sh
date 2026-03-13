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
    show_new_line
    return 1
  fi

  if ! gh auth status &>/dev/null; then
    show_setup_message "Authenticate: gh auth login"
    show_new_line
    return 1
  fi

  return 0
}

_check_github_rate_limit() {
  local response_data="$1"

  if echo "$response_data" | grep -q "rate limit" 2>>"$LOG_FILE"; then
    echo_yellow "GitHub API rate limit exceeded"
    echo_gray "  → Wait a few minutes or check: gh api rate_limit"
    show_new_line
    return 1
  fi

  return 0
}

_format_pr_ci_status() {
  local ci_state="$1"

  case "$ci_state" in
    SUCCESS) echo "✅" ;;
    PENDING) echo "⏳" ;;
    FAILURE | ERROR) echo "❌" ;;
    *) echo "❓" ;;
  esac
}

_format_pr_merge_status() {
  local mergeable="$1"

  case "$mergeable" in
    MERGEABLE) show_new_line ;;
    CONFLICTING) echo " ⚠️  CONFLICTS" ;;
    UNKNOWN) echo " 🔄" ;;
    *) show_new_line ;;
  esac
}

_display_pr_comments() {
  local pr_json="$1"
  local username="$2"
  local unresolved_count="$3"

  if [ "$unresolved_count" -gt 0 ]; then
    echo_yellow "    💬 ${unresolved_count} unresolved comment(s)"

    local filter='.reviewThreads.nodes[] | select(.isResolved == false and .comments.nodes[0].author.login != "'"$username"'")'
    printf '%s' "$pr_json" | jq -r "$filter | .comments.nodes[0].url" 2>>"$LOG_FILE" | head -3 | while read -r url; do
      echo_gray "       → $url"
    done
  fi
}

_extract_service_labels() {
  local files_json="$1"

  if [ -z "$files_json" ] || [ "$files_json" = "null" ]; then
    echo ""
    return 0
  fi

  local services=$(printf '%s' "$files_json" | jq -r '
    [.[] | .path |
      if startswith("services/") then split("/")[1]
      elif startswith("e2e/") then "e2e"
      else empty
      end
    ] | unique | join(", ")
  ' 2>/dev/null)

  if [ -n "$services" ]; then
    echo "[${services}]"
  else
    echo ""
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

  local filter='[.reviewThreads.nodes[] | select(.isResolved == false and .comments.nodes[0].author.login != "'"$username"'")]'
  local unresolved_count=$(printf '%s' "$pr_json" | jq "$filter | length")

  local ci_icon=$(_format_pr_ci_status "$ci_state")
  local merge_icon=$(_format_pr_merge_status "$mergeable")

  if [ -n "$GITHUB_REPO" ]; then
    local files_nodes=$(printf '%s' "$pr_json" | jq '.files.nodes // []')
    local service_labels=$(_extract_service_labels "$files_nodes")
    if [ -n "$service_labels" ]; then
      echo "  • #${pr_number}: ${pr_title} ${service_labels}"
    else
      echo "  • #${pr_number}: ${pr_title}"
    fi
  else
    echo "  • ${pr_repo}#${pr_number}: ${pr_title}"
  fi
  echo "    ${ci_icon} CI${merge_icon}"

  _display_pr_comments "$pr_json" "$username" "$unresolved_count"

  echo "    🔗 $pr_url"
  show_new_line
}

_build_authored_and_review_requested_prs_query() {
  local repo_filter=""
  local files_field=""
  if [ -n "$GITHUB_REPO" ]; then
    repo_filter=" repo:${GITHUB_REPO}"
    files_field="
        files(first: 100) { nodes { path } }"
  fi

  cat <<EOF
query {
  authored: search(query: "type:pr is:open author:@me${repo_filter}", type: ISSUE, first: 25) {
    nodes {
      ... on PullRequest {
        number title url repository { nameWithOwner } mergeable
        commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
        reviewThreads(first: 50) { nodes { isResolved comments(first: 1) { nodes { author { login } url } } } }${files_field}
      }
    }
  }
  reviewRequested: search(query: "type:pr is:open review-requested:@me${repo_filter}", type: ISSUE, first: 25) {
    nodes { ... on PullRequest { number title url repository { nameWithOwner } } }
  }
}
EOF
}

_display_authored_prs() {
  local pr_data="$1"
  local username="$2"
  local authored_count="$3"
  local max_prs="${MAX_GITHUB_PRS:-5}"

  if [ "$authored_count" -gt "$max_prs" ]; then
    echo_cyan "Your Open PRs (showing $max_prs of $authored_count):"
    echo_gray "  → Adjust GOODMORNING_MAX_GITHUB_PRS in config to show more"
  else
    echo_cyan "Your Open PRs ($authored_count):"
  fi
  show_new_line

  local jq_filter='.data.authored.nodes[:'"$max_prs"'] | .[] | @json'
  printf '%s' "$pr_data" | jq -r "$jq_filter" 2>>"$LOG_FILE" | while read -r pr_json; do
    _display_single_pr "$pr_json" "$username"
  done
}

_display_review_requested_prs() {
  local pr_data="$1"
  local review_requested_count="$2"
  local max_prs="${MAX_GITHUB_PRS:-5}"

  if [ "$review_requested_count" -gt "$max_prs" ]; then
    echo_cyan "Awaiting Your Review (showing $max_prs of $review_requested_count):"
    echo_gray "  → Adjust GOODMORNING_MAX_GITHUB_PRS in config to show more"
  else
    echo_cyan "Awaiting Your Review ($review_requested_count):"
  fi
  show_new_line

  local jq_filter='.data.reviewRequested.nodes[:'"$max_prs"'] | .[]'
  local jq_format='"  • \(.repository.nameWithOwner)#\(.number): \(.title)\n    🔗 \(.url)\n"'
  printf '%s' "$pr_data" | jq -r "$jq_filter | $jq_format" 2>>"$LOG_FILE"
  show_new_line
}

show_github_prs() {
  print_section "🔀 GitHub PR Review:" "yellow"

  _validate_github_setup || return 0

  local username=$(gh api user --jq '.login' 2>>"$LOG_FILE")
  if [ -z "$username" ]; then
    echo "Unable to fetch GitHub username"
    show_new_line
    return 0
  fi

  local pr_query=$(_build_authored_and_review_requested_prs_query)
  local pr_data=$(fetch_with_spinner "Fetching PRs..." gh api graphql -f query="$pr_query" 2>>"$LOG_FILE")

  if [ $? -ne 0 ] || [ -z "$pr_data" ]; then
    _check_github_rate_limit "$pr_data" || echo "Unable to fetch PR data"
    show_new_line
    return 0
  fi

  local authored_count=$(printf '%s' "$pr_data" | jq '.data.authored.nodes | length' 2>>"$LOG_FILE")
  local review_requested_count=$(printf '%s' "$pr_data" | jq '.data.reviewRequested.nodes | length' 2>>"$LOG_FILE")

  if [ "$authored_count" -eq 0 ] && [ "$review_requested_count" -eq 0 ]; then
    echo "No open PRs requiring attention"
    show_new_line
    return 0
  fi

  [ "$authored_count" -gt 0 ] && _display_authored_prs "$pr_data" "$username" "$authored_count"
  [ "$review_requested_count" -gt 0 ] && _display_review_requested_prs "$pr_data" "$review_requested_count"
}

_display_single_issue() {
  local issue_json="$1"

  local issue_repo=$(printf '%s' "$issue_json" | jq -r '.repository.nameWithOwner')
  local issue_title=$(printf '%s' "$issue_json" | jq -r '.title')
  local issue_url=$(printf '%s' "$issue_json" | jq -r '.url')
  local issue_number=$(printf '%s' "$issue_json" | jq -r '.number')
  local comment_count=$(printf '%s' "$issue_json" | jq -r '.comments.totalCount')
  local labels=$(printf '%s' "$issue_json" | jq -r '[.labels.nodes[].name] | join(", ")')

  if [ -n "$GITHUB_REPO" ]; then
    echo "  • #${issue_number}: ${issue_title}"
  else
    echo "  • ${issue_repo}#${issue_number}: ${issue_title}"
  fi

  if [ -n "$labels" ] && [ "$labels" != "" ]; then
    echo_gray "    🏷️  $labels"
  fi

  if [ "$comment_count" -gt 0 ]; then
    echo_gray "    💬 $comment_count comment(s)"
  fi

  echo "    🔗 $issue_url"
  show_new_line
}

_build_assigned_issues_query() {
  local repo_filter=""
  if [ -n "$GITHUB_REPO" ]; then
    repo_filter=" repo:${GITHUB_REPO}"
  fi

  cat <<EOF
query {
  search(query: "type:issue is:open assignee:@me${repo_filter}", type: ISSUE, first: 25) {
    issueCount
    nodes {
      ... on Issue {
        number title url
        repository { nameWithOwner }
        labels(first: 5) { nodes { name } }
        comments { totalCount }
        createdAt
      }
    }
  }
}
EOF
}

show_github_issues() {
  print_section "📋 GitHub Issues:" "yellow"

  _validate_github_setup || return 0

  local issues_query=$(_build_assigned_issues_query)
  local issues_data=$(fetch_with_spinner "Fetching issues..." gh api graphql -f query="$issues_query" 2>>"$LOG_FILE")

  if [ $? -ne 0 ] || [ -z "$issues_data" ]; then
    _check_github_rate_limit "$issues_data" || echo "Unable to fetch issues"
    show_new_line
    return 0
  fi

  local issue_count=$(printf '%s' "$issues_data" | jq '.data.search.issueCount' 2>>"$LOG_FILE")

  if [ "$issue_count" -eq 0 ]; then
    echo "No open issues assigned to you"
    show_new_line
    return 0
  fi

  local max_issues="${MAX_GITHUB_ISSUES:-5}"
  if [ "$issue_count" -gt "$max_issues" ]; then
    echo "You have ${issue_count} open issue(s) (showing $max_issues):"
    echo_gray "  → Adjust GOODMORNING_MAX_GITHUB_ISSUES in config to show more"
  else
    echo "You have ${issue_count} open issue(s) assigned:"
  fi
  show_new_line

  local jq_filter='.data.search.nodes[:'"$max_issues"'] | .[] | @json'
  printf '%s' "$issues_data" | jq -r "$jq_filter" 2>>"$LOG_FILE" | while read -r issue_json; do
    _display_single_issue "$issue_json"
  done
}
