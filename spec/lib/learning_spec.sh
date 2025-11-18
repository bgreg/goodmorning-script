#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'lib/learning.sh - Daily Learning System'
  Include lib/colors.sh
  Include lib/core.sh
  Include lib/learning.sh

  Describe 'show_daily_learning function'
    setup() {
      TEST_DIR=$(mktemp -d)
      export LEARNING_SOURCES_FILE="$TEST_DIR/learning-sources.txt"
      export SCRIPT_DIR="$PROJECT_ROOT"

      # Create test learning sources file
      cat > "$LEARNING_SOURCES_FILE" <<'EOF'
[Ruby]
https://ruby-doc.org/core/|Ruby Core Documentation
https://guides.rubyonrails.org/|Rails Guides

[JavaScript]
https://developer.mozilla.org/en-US/docs/Web/JavaScript|MDN JavaScript
https://javascript.info/|Modern JavaScript Tutorial
EOF
    }

    cleanup() {
      [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
      unset LEARNING_SOURCES_FILE
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
      The stderr should not be blank
    End

    It 'handles missing learning sources file'
      export LEARNING_SOURCES_FILE="/nonexistent/file.txt"
      When call show_daily_learning
      The output should include "not found"
      The status should be success
    End

    It 'handles empty learning sources file'
      echo "" > "$LEARNING_SOURCES_FILE"
      When call show_daily_learning
      The output should include "No learning"
      The status should be success
    End
  End

  Describe 'Learning sources file format'
    setup() {
      TEST_DIR=$(mktemp -d)
      SOURCES_FILE="$TEST_DIR/sources.txt"
    }

    cleanup() {
      [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
    }

    Before 'setup'
    After 'cleanup'

    It 'supports category headers'
      echo '[Test Category]' > "$SOURCES_FILE"
      When call grep '\[Test Category\]' "$SOURCES_FILE"
      The status should be success
      The output should not be blank
    End

    It 'supports URL|Title format'
      echo 'https://example.com|Example Title' > "$SOURCES_FILE"
      When call grep 'https://example.com|Example Title' "$SOURCES_FILE"
      The status should be success
      The output should not be blank
    End

    It 'supports comments with # prefix'
      echo '# This is a comment' > "$SOURCES_FILE"
      echo 'https://example.com|Title' >> "$SOURCES_FILE"
      When call grep -v '^#' "$SOURCES_FILE"
      The output should include "https://example.com"
    End

    It 'supports multiple categories'
      cat > "$SOURCES_FILE" <<'EOF'
[Category 1]
https://example1.com|Title 1

[Category 2]
https://example2.com|Title 2
EOF
      When call grep -c '^\[' "$SOURCES_FILE"
      The output should equal 2
    End
  End
End
