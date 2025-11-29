#!/usr/bin/env zsh

###############################################################################
# GitHub Functions
#
# Displays GitHub PR and Issue review information:
# - Open PRs assigned to you with CI status, unresolved comments, merge conflicts
# - Open issues assigned to you
###############################################################################

show_github_prs() {
  print_section "🔀 GitHub PR Review:" "yellow"

  if ! command_exists gh; then
    show_setup_message "Install GitHub CLI: brew install gh"
    echo ""
    return 0
  fi

  if ! gh auth status &>/dev/null; then
    show_setup_message "Authenticate: gh auth login"
    echo ""
    return 0
  fi

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
    # Check for rate limit
    if echo "$pr_data" | grep -q "rate limit" 2>/dev/null; then
      echo_yellow "GitHub API rate limit exceeded"
      echo_gray "  → Wait a few minutes or check: gh api rate_limit"
    else
      echo "Unable to fetch PR data"
    fi
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

    local repo title url number mergeable ci_state unresolved_count ci_icon merge_icon
    printf '%s' "$pr_data" | jq -r '.data.authored.nodes[:'"$max_prs"'] | .[] | @json' 2>> "$LOG_FILE" | while read -r pr_json; do
      repo=$(printf '%s' "$pr_json" | jq -r '.repository.nameWithOwner')
      title=$(printf '%s' "$pr_json" | jq -r '.title')
      url=$(printf '%s' "$pr_json" | jq -r '.url')
      number=$(printf '%s' "$pr_json" | jq -r '.number')
      mergeable=$(printf '%s' "$pr_json" | jq -r '.mergeable')
      ci_state=$(printf '%s' "$pr_json" | jq -r '.commits.nodes[0].commit.statusCheckRollup.state // "UNKNOWN"')

      # Count unresolved review threads not authored by user
      unresolved_count=$(printf '%s' "$pr_json" | jq '[.reviewThreads.nodes[] | select(.isResolved == false and .comments.nodes[0].author.login != "'"$username"'")] | length')

      # Format CI status
      case "$ci_state" in
        SUCCESS) ci_icon="✅" ;;
        PENDING) ci_icon="⏳" ;;
        FAILURE|ERROR) ci_icon="❌" ;;
        *) ci_icon="❓" ;;
      esac

      # Format merge status
      case "$mergeable" in
        MERGEABLE) merge_icon="" ;;
        CONFLICTING) merge_icon=" ⚠️  CONFLICTS" ;;
        UNKNOWN) merge_icon=" 🔄" ;;
        *) merge_icon="" ;;
      esac

      echo "  • ${repo}#${number}: ${title}"
      echo "    ${ci_icon} CI${merge_icon}"

      if [ "$unresolved_count" -gt 0 ]; then
        echo_yellow "    💬 ${unresolved_count} unresolved comment(s)"

        # List comment URLs
        printf '%s' "$pr_json" | jq -r '.reviewThreads.nodes[] | select(.isResolved == false and .comments.nodes[0].author.login != "'"$username"'") | .comments.nodes[0].url' 2>> "$LOG_FILE" | head -3 | while read -r comment_url; do
          echo_gray "       → $comment_url"
        done
      fi

      echo "    🔗 $url"
      echo ""
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

show_github_issues() {
  print_section "📋 GitHub Issues:" "yellow"

  if ! command_exists gh; then
    show_setup_message "Install GitHub CLI: brew install gh"
    echo ""
    return 0
  fi

  if ! gh auth status &>/dev/null; then
    show_setup_message "Authenticate: gh auth login"
    echo ""
    return 0
  fi

  # Fetch issues assigned to user
  local issues_query='query { search(query: "type:issue is:open assignee:@me", type: ISSUE, first: 25) { issueCount nodes { ... on Issue { number title url repository { nameWithOwner } labels(first: 5) { nodes { name } } comments { totalCount } createdAt } } } }'

  local issues_data
  issues_data=$(fetch_with_spinner "Fetching issues..." gh api graphql -f query="$issues_query" 2>> "$LOG_FILE")

  if [ $? -ne 0 ] || [ -z "$issues_data" ]; then
    # Check for rate limit
    if echo "$issues_data" | grep -q "rate limit" 2>/dev/null; then
      echo_yellow "GitHub API rate limit exceeded"
      echo_gray "  → Wait a few minutes or check: gh api rate_limit"
    else
      echo "Unable to fetch issues"
    fi
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

  local repo title url number comment_count labels
  printf '%s' "$issues_data" | jq -r '.data.search.nodes[:'"$max_issues"'] | .[] | @json' 2>> "$LOG_FILE" | while read -r issue_json; do
    repo=$(printf '%s' "$issue_json" | jq -r '.repository.nameWithOwner')
    title=$(printf '%s' "$issue_json" | jq -r '.title')
    url=$(printf '%s' "$issue_json" | jq -r '.url')
    number=$(printf '%s' "$issue_json" | jq -r '.number')
    comment_count=$(printf '%s' "$issue_json" | jq -r '.comments.totalCount')
    labels=$(printf '%s' "$issue_json" | jq -r '[.labels.nodes[].name] | join(", ")')

    echo "  • ${repo}#${number}: ${title}"

    if [ -n "$labels" ] && [ "$labels" != "" ]; then
      echo_gray "    🏷️  $labels"
    fi

    if [ "$comment_count" -gt 0 ]; then
      echo_gray "    💬 $comment_count comment(s)"
    fi

    echo "    🔗 $url"
    echo ""
  done
}
