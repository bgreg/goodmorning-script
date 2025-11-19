#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'lib/learning.sh - Daily Learning System'
  Include lib/colors.sh
  Include lib/core.sh
  Include lib/sitemap.sh
  Include lib/learning.sh

  Describe 'show_daily_learning function'
    setup() {
      TEST_DIR=$(mktemp -d)
      export SCRIPT_DIR="$PROJECT_ROOT"
      export GOODMORNING_CONFIG_DIR="$TEST_DIR"

      # Create test learning sources JSON file
      cat > "$TEST_DIR/learning-sources.json" <<'EOF'
{
  "sitemaps": [],
  "static": [
    {
      "title": "Test Documentation",
      "url": "https://example.com/docs"
    }
  ]
}
EOF
    }

    cleanup() {
      [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
      unset GOODMORNING_CONFIG_DIR
    }

    Before 'setup'
    After 'cleanup'

    It 'is defined'
      When call type show_daily_learning
      The status should be success
      The output should include "function"
    End

    It 'displays a learning resource when file exists'
      When call show_daily_learning
      The output should include "📚"
      The status should be success
    End

    It 'handles missing learning sources file'
      rm -f "$TEST_DIR/learning-sources.json"
      export SCRIPT_DIR="/nonexistent"
      When call show_daily_learning
      The output should include "not found"
      The status should be success
    End

    It 'handles empty static array'
      cat > "$TEST_DIR/learning-sources.json" <<'EOF'
{
  "sitemaps": [],
  "static": []
}
EOF
      When call show_daily_learning
      The output should include "No static sources"
      The status should be success
    End
  End

  Describe 'Learning sources JSON format'
    setup() {
      TEST_DIR=$(mktemp -d)
      SOURCES_FILE="$TEST_DIR/learning-sources.json"
    }

    cleanup() {
      [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
    }

    Before 'setup'
    After 'cleanup'

    It 'supports sitemaps array'
      cat > "$SOURCES_FILE" <<'EOF'
{
  "sitemaps": [
    {"title": "PostgreSQL", "sitemap": "https://www.postgresql.org/sitemap.xml"}
  ],
  "static": []
}
EOF
      When call jq '.sitemaps | length' "$SOURCES_FILE"
      The output should equal 1
    End

    It 'supports static array'
      cat > "$SOURCES_FILE" <<'EOF'
{
  "sitemaps": [],
  "static": [
    {"title": "Python Docs", "url": "https://docs.python.org/3/"}
  ]
}
EOF
      When call jq '.static | length' "$SOURCES_FILE"
      The output should equal 1
    End

    It 'supports multiple entries in each array'
      cat > "$SOURCES_FILE" <<'EOF'
{
  "sitemaps": [
    {"title": "Site 1", "sitemap": "https://example1.com/sitemap.xml"},
    {"title": "Site 2", "sitemap": "https://example2.com/sitemap.xml"}
  ],
  "static": [
    {"title": "Doc 1", "url": "https://example1.com/docs"},
    {"title": "Doc 2", "url": "https://example2.com/docs"}
  ]
}
EOF
      When call jq '.sitemaps | length' "$SOURCES_FILE"
      The output should equal 2
    End
  End
End
