#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'lib/sitemap.sh - Sitemap Utilities'
  Include lib/utilities.sh
  Include lib/app/sitemap.sh

  Describe 'extract_title_from_url function'
    It 'is defined'
      When call type extract_title_from_url
      The status should be success
      The output should include "function"
    End

    It 'extracts title from simple URL'
      When call extract_title_from_url "https://example.com/my-page"
      The output should equal "My Page"
      The status should be success
    End

    It 'handles .html extension'
      When call extract_title_from_url "https://example.com/docs/getting-started.html"
      The output should equal "Getting Started"
      The status should be success
    End

    It 'handles .htm extension'
      When call extract_title_from_url "https://example.com/page.htm"
      The output should equal "Page"
      The status should be success
    End

    It 'handles .php extension'
      When call extract_title_from_url "https://example.com/contact.php"
      The output should equal "Contact"
      The status should be success
    End

    It 'handles .aspx extension'
      When call extract_title_from_url "https://example.com/form.aspx"
      The output should equal "Form"
      The status should be success
    End

    It 'handles underscores in URL'
      When call extract_title_from_url "https://example.com/user_guide"
      The output should equal "User Guide"
      The status should be success
    End

    It 'handles mixed dashes and underscores'
      When call extract_title_from_url "https://example.com/api-reference_v2"
      The output should equal "Api Reference V2"
      The status should be success
    End

    It 'handles trailing slash'
      When call extract_title_from_url "https://example.com/documentation/"
      The output should equal "Documentation"
      The status should be success
    End

    It 'handles deep nested paths'
      When call extract_title_from_url "https://docs.example.com/en/v2/api/endpoints/users"
      The output should equal "Users"
      The status should be success
    End

    It 'converts to title case'
      When call extract_title_from_url "https://example.com/UPPERCASE-page"
      The output should equal "Uppercase Page"
      The status should be success
    End
  End

  Describe 'fetch_sitemap_urls function'
    It 'is defined'
      When call type fetch_sitemap_urls
      The status should be success
      The output should include "function"
    End
  End

  Describe 'fetch_doc_sitemap_urls function'
    It 'is defined'
      When call type fetch_doc_sitemap_urls
      The status should be success
      The output should include "function"
    End
  End

  Describe 'pick_random_from_json function'
    setup() {
      TEST_DIR=$(mktemp -d)
    }

    cleanup() {
      [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
    }

    Before 'setup'
    After 'cleanup'

    It 'is defined'
      When call type pick_random_from_json
      The status should be success
      The output should include "function"
    End

    It 'returns failure for empty array'
      echo '{"items": []}' > "$TEST_DIR/empty.json"
      When call pick_random_from_json "$TEST_DIR/empty.json" ".items"
      The status should be failure
    End

    It 'returns item from single-element array'
      echo '{"items": [{"name": "test"}]}' > "$TEST_DIR/single.json"
      When call pick_random_from_json "$TEST_DIR/single.json" ".items"
      The output should include "test"
      The status should be success
    End
  End
End
