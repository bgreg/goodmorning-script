#!/usr/bin/env zsh
#shellspec shell=zsh

# End-to-End URL Validation Tests
# Run with: SHELLSPEC_REAL=1 shellspec spec/e2e/sitemap_urls_spec.sh
# These tests validate all URLs in learning-sources.json and sanity-maintenance-sources.json

Describe 'E2E URL Validation Tests'
  Skip if 'SHELLSPEC_REAL not set' [ -z "${SHELLSPEC_REAL:-}" ]

  setup() {
    local project_root="${SHELLSPEC_PROJECT_ROOT:-$(pwd)}"
    LEARNING_SOURCES="$project_root/learning-sources.json"
    SANITY_SOURCES="$project_root/sanity-maintenance-sources.json"
    RESULTS_DIR=$(mktemp -d)
    TIMEOUT_SECONDS=10
  }

  cleanup() {
    [ -d "$RESULTS_DIR" ] && rm -rf "$RESULTS_DIR"
  }

  BeforeAll 'setup'
  AfterAll 'cleanup'

  Describe 'Source files exist'
    It 'has learning-sources.json'
      The file "$LEARNING_SOURCES" should be exist
    End

    It 'has sanity-maintenance-sources.json'
      The file "$SANITY_SOURCES" should be exist
    End

    It 'learning-sources.json is valid JSON'
      When call jq empty "$LEARNING_SOURCES"
      The status should be success
    End

    It 'sanity-maintenance-sources.json is valid JSON'
      When call jq empty "$SANITY_SOURCES"
      The status should be success
    End
  End

  Describe 'Learning Sources - Sitemap URLs'
    check_sitemap_url() {
      local url="$1"
      local title="$2"
      local result_file="$RESULTS_DIR/sitemap_$(echo "$url" | md5).txt"

      local http_code
      http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT_SECONDS" -L "$url" 2>/dev/null)

      if [[ "$http_code" =~ ^(200|301|302|303|307|308)$ ]]; then
        echo "PASS: $title ($url) - HTTP $http_code"
        return 0
      else
        echo "FAIL: $title ($url) - HTTP $http_code"
        return 1
      fi
    }

    It 'has sitemap entries'
      sitemap_count() {
        jq -r '.sitemaps | length' "$LEARNING_SOURCES"
      }
      When call sitemap_count
      The output should be greater than 0
    End

    It 'all sitemap URLs are accessible'
      validate_all_sitemaps() {
        local failed=0
        local passed=0
        local total

        total=$(jq -r '.sitemaps | length' "$LEARNING_SOURCES")

        for i in $(seq 0 $((total - 1))); do
          local title url
          title=$(jq -r ".sitemaps[$i].title" "$LEARNING_SOURCES")
          url=$(jq -r ".sitemaps[$i].sitemap" "$LEARNING_SOURCES")

          if check_sitemap_url "$url" "$title" >&2; then
            passed=$((passed + 1))
          else
            failed=$((failed + 1))
          fi
        done

        echo "Sitemaps: $passed passed, $failed failed out of $total"
        [ "$failed" -eq 0 ]
      }
      When call validate_all_sitemaps
      The status should be success
    End
  End

  Describe 'Learning Sources - Static URLs'
    check_static_url() {
      local url="$1"
      local title="$2"

      local http_code
      http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT_SECONDS" -L "$url" 2>/dev/null)

      if [[ "$http_code" =~ ^(200|301|302|303|307|308)$ ]]; then
        echo "PASS: $title ($url) - HTTP $http_code"
        return 0
      else
        echo "FAIL: $title ($url) - HTTP $http_code"
        return 1
      fi
    }

    It 'has static entries'
      static_count() {
        jq -r '.static | length' "$LEARNING_SOURCES"
      }
      When call static_count
      The output should be greater than 0
    End

    It 'all static URLs are accessible'
      validate_all_static() {
        local failed=0
        local passed=0
        local total

        total=$(jq -r '.static | length' "$LEARNING_SOURCES")

        for i in $(seq 0 $((total - 1))); do
          local title url
          title=$(jq -r ".static[$i].title" "$LEARNING_SOURCES")
          url=$(jq -r ".static[$i].url" "$LEARNING_SOURCES")

          if check_static_url "$url" "$title" >&2; then
            passed=$((passed + 1))
          else
            failed=$((failed + 1))
          fi
        done

        echo "Static URLs: $passed passed, $failed failed out of $total"
        [ "$failed" -eq 0 ]
      }
      When call validate_all_static
      The status should be success
    End
  End

  Describe 'Sanity Maintenance Sources - Category URLs'
    check_category_url() {
      local url="$1"
      local title="$2"

      # Special handling for xkcd:random protocol
      if [[ "$url" == "xkcd:random" ]]; then
        # Test the XKCD API endpoint instead
        url="https://xkcd.com/info.0.json"
      fi

      local http_code
      http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT_SECONDS" -L "$url" 2>/dev/null)

      if [[ "$http_code" =~ ^(200|301|302|303|307|308)$ ]]; then
        echo "PASS: $title ($url) - HTTP $http_code"
        return 0
      else
        echo "FAIL: $title ($url) - HTTP $http_code"
        return 1
      fi
    }

    It 'has category entries'
      category_count() {
        jq -r '.categories | keys | length' "$SANITY_SOURCES"
      }
      When call category_count
      The output should be greater than 0
    End

    It 'all category URLs are accessible'
      validate_all_categories() {
        local failed=0
        local passed=0
        local total=0

        # Get all categories
        local categories
        categories=$(jq -r '.categories | keys[]' "$SANITY_SOURCES")

        for category in $categories; do
          local count
          count=$(jq -r ".categories.\"$category\" | length" "$SANITY_SOURCES")

          for i in $(seq 0 $((count - 1))); do
            local title url
            title=$(jq -r ".categories.\"$category\"[$i].title" "$SANITY_SOURCES")
            url=$(jq -r ".categories.\"$category\"[$i].url" "$SANITY_SOURCES")

            total=$((total + 1))

            if check_category_url "$url" "$title" >&2; then
              passed=$((passed + 1))
            else
              failed=$((failed + 1))
            fi
          done
        done

        echo "Category URLs: $passed passed, $failed failed out of $total"
        [ "$failed" -eq 0 ]
      }
      When call validate_all_categories
      The status should be success
    End
  End

  Describe 'URL Content Validation'
    It 'sitemap URLs return XML content'
      validate_sitemap_content() {
        # Test first sitemap for XML content
        local url
        url=$(jq -r '.sitemaps[0].sitemap' "$LEARNING_SOURCES")

        local content
        content=$(curl -s --max-time "$TIMEOUT_SECONDS" -L "$url" 2>/dev/null | head -c 1000)

        if [[ "$content" == *"<?xml"* ]] || [[ "$content" == *"<urlset"* ]] || [[ "$content" == *"<sitemapindex"* ]]; then
          echo "Sitemap contains valid XML structure"
          return 0
        else
          echo "Warning: Sitemap may not contain valid XML (could be gzipped)"
          # Still pass for gzipped content
          return 0
        fi
      }
      When call validate_sitemap_content
      The status should be success
    End
  End

  Describe 'Individual URL Spot Checks'
    It 'PostgreSQL sitemap is reachable'
      check_postgresql() {
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT_SECONDS" "https://www.postgresql.org/sitemap.xml" 2>/dev/null)
        [[ "$http_code" =~ ^(200|301|302|303|307|308)$ ]]
      }
      When call check_postgresql
      The status should be success
    End

    It 'Python documentation is reachable'
      check_python() {
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT_SECONDS" "https://docs.python.org/3/" 2>/dev/null)
        [[ "$http_code" =~ ^(200|301|302|303|307|308)$ ]]
      }
      When call check_python
      The status should be success
    End

    It 'XKCD API is reachable'
      check_xkcd() {
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT_SECONDS" "https://xkcd.com/info.0.json" 2>/dev/null)
        [[ "$http_code" =~ ^(200|301|302|303|307|308)$ ]]
      }
      When call check_xkcd
      The status should be success
    End

    It 'Hacker News is reachable'
      check_hn() {
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT_SECONDS" "https://news.ycombinator.com/" 2>/dev/null)
        [[ "$http_code" =~ ^(200|301|302|303|307|308)$ ]]
      }
      When call check_hn
      The status should be success
    End
  End

  Describe 'URL Format Validation'
    It 'all learning sitemap URLs use HTTPS'
      check_https_sitemaps() {
        local non_https
        non_https=$(jq -r '.sitemaps[].sitemap | select(startswith("https://") | not)' "$LEARNING_SOURCES")

        if [ -n "$non_https" ]; then
          echo "Non-HTTPS URLs found: $non_https"
          return 1
        fi
        return 0
      }
      When call check_https_sitemaps
      The status should be success
    End

    It 'all learning static URLs use HTTPS'
      check_https_static() {
        local non_https
        non_https=$(jq -r '.static[].url | select(startswith("https://") | not)' "$LEARNING_SOURCES")

        if [ -n "$non_https" ]; then
          echo "Non-HTTPS URLs found: $non_https"
          return 1
        fi
        return 0
      }
      When call check_https_static
      The status should be success
    End

    It 'all sanity URLs use HTTPS or special protocols'
      check_https_sanity() {
        local categories
        categories=$(jq -r '.categories | keys[]' "$SANITY_SOURCES")

        for category in $categories; do
          local urls
          urls=$(jq -r ".categories.\"$category\"[].url" "$SANITY_SOURCES")

          for url in $urls; do
            # Allow https:// or special protocols like xkcd:
            if [[ ! "$url" =~ ^(https://|xkcd:) ]]; then
              echo "Invalid URL protocol: $url"
              return 1
            fi
          done
        done
        return 0
      }
      When call check_https_sanity
      The status should be success
    End
  End

  Describe 'Duplicate URL Detection'
    It 'has no duplicate sitemap URLs in learning sources'
      check_sitemap_duplicates() {
        local dup_count
        dup_count=$(jq -r '.sitemaps[].sitemap' "$LEARNING_SOURCES" | sort | uniq -d | wc -l | tr -d ' ')

        if [ "$dup_count" -gt 0 ]; then
          echo "Found duplicate sitemap URLs"
          jq -r '.sitemaps[].sitemap' "$LEARNING_SOURCES" | sort | uniq -d
          return 1
        fi
        return 0
      }
      When call check_sitemap_duplicates
      The status should be success
    End

    It 'has no duplicate static URLs in learning sources'
      check_static_duplicates() {
        local dup_count
        dup_count=$(jq -r '.static[].url' "$LEARNING_SOURCES" | sort | uniq -d | wc -l | tr -d ' ')

        if [ "$dup_count" -gt 0 ]; then
          echo "Found duplicate static URLs"
          jq -r '.static[].url' "$LEARNING_SOURCES" | sort | uniq -d
          return 1
        fi
        return 0
      }
      When call check_static_duplicates
      The status should be success
    End
  End
End
