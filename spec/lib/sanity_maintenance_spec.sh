#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'lib/sanity_maintenance.sh - Sanity Maintenance System'
  Include lib/colors.sh
  Include lib/core.sh
  Include lib/sitemap.sh
  Include lib/sanity_maintenance.sh

  Describe 'show_sanity_maintenance function'
    setup() {
      TEST_DIR=$(mktemp -d)
      export SCRIPT_DIR="$PROJECT_ROOT"
      export GOODMORNING_CONFIG_DIR="$TEST_DIR"

      # Create test sources file with categories
      cat > "$TEST_DIR/sanity-maintenance-sources.json" <<'EOF'
{
  "sitemaps": [],
  "categories": {
    "comics": [
      {
        "title": "Test Comic",
        "url": "https://example.com/comic"
      }
    ]
  }
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
      When call type show_sanity_maintenance
      The status should be success
      The output should include "function"
    End

    It 'displays section header'
      When call show_sanity_maintenance
      The output should include "🤪"
      The output should include "Sanity Maintenance"
      The status should be success
    End

    It 'shows categorized resource from JSON'
      When call show_sanity_maintenance
      The output should include "Comics"
      The status should be success
    End

    It 'handles missing sources file'
      rm -f "$TEST_DIR/sanity-maintenance-sources.json"
      export SCRIPT_DIR="/nonexistent"
      When call show_sanity_maintenance
      The output should include "not found"
      The status should be success
    End
  End

  Describe '_fetch_random_xkcd function'
    It 'is defined'
      When call type _fetch_random_xkcd
      The status should be success
      The output should include "function"
    End
  End

  Describe '_show_from_category function'
    setup() {
      TEST_DIR=$(mktemp -d)
      export SCRIPT_DIR="$PROJECT_ROOT"
    }

    cleanup() {
      [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
    }

    Before 'setup'
    After 'cleanup'

    It 'is defined'
      When call type _show_from_category
      The status should be success
      The output should include "function"
    End

    It 'handles empty category'
      echo '{"sitemaps": [], "categories": {"comics": []}}' > "$TEST_DIR/empty.json"
      When call _show_from_category "$TEST_DIR/empty.json" "comics"
      The status should be failure
    End
  End

  Describe '_show_non_comic_resource function'
    It 'is defined'
      When call type _show_non_comic_resource
      The status should be success
      The output should include "function"
    End
  End

  Describe 'Sanity maintenance sources JSON format'
    setup() {
      TEST_DIR=$(mktemp -d)
      SOURCES_FILE="$TEST_DIR/sanity-maintenance-sources.json"
    }

    cleanup() {
      [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
    }

    Before 'setup'
    After 'cleanup'

    It 'supports categories object'
      cat > "$SOURCES_FILE" <<'EOF'
{
  "sitemaps": [],
  "categories": {
    "comics": [{"title": "Test", "url": "https://example.com"}]
  }
}
EOF
      When call jq '.categories | keys | length' "$SOURCES_FILE"
      The output should equal 1
    End

    It 'supports multiple categories'
      cat > "$SOURCES_FILE" <<'EOF'
{
  "sitemaps": [],
  "categories": {
    "comics": [{"title": "Comic", "url": "https://example.com/comic"}],
    "satire": [{"title": "Satire", "url": "https://example.com/satire"}],
    "forums": [{"title": "Forum", "url": "https://example.com/forum"}]
  }
}
EOF
      When call jq '.categories | keys | length' "$SOURCES_FILE"
      The output should equal 3
    End

    It 'supports special URL types'
      cat > "$SOURCES_FILE" <<'EOF'
{
  "sitemaps": [],
  "categories": {
    "comics": [{"title": "XKCD", "url": "xkcd:random"}]
  }
}
EOF
      When call jq -r '.categories.comics[0].url' "$SOURCES_FILE"
      The output should equal "xkcd:random"
    End
  End
End
