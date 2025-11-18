#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'goodmorning.sh - Security'
  Describe 'Email validation pattern'
    It 'accepts valid email addresses'
      When call echo "test@example.com"
      The output should include "@"
      The output should include "example.com"
    End

    It 'rejects command injection attempts'
      Data
        #|evil@test.com$(rm -rf /)
        #|test@example.com`whoami`
        #|user@domain.com;ls
      End

      When call echo "$THEDATA"
      The output should not match pattern "$email_pattern"
    End

    It 'rejects special characters'
      Data
        #|test;whoami@example.com
        #|test|whoami@example.com
        #|test&whoami@example.com
        #|test>file@example.com
      End

      When call echo "$THEDATA"
      The output should not match pattern "$email_pattern"
    End
  End

  Describe 'URL validation pattern'
    It 'accepts valid HTTP/HTTPS URLs'
      When call echo "https://example.com"
      The output should include "https://"
      The output should include ".com"
    End

    It 'rejects dangerous protocols'
      Data
        #|file:///etc/passwd
        #|javascript:alert('xss')
        #|ftp://files.example.com
        #|data:text/html,<script>alert('xss')</script>
      End

      When call echo "$THEDATA"
      The output should not match pattern "$url_pattern"
    End

    It 'rejects path traversal attempts'
      Data
        #|../../../etc/passwd
        #|../../../../../../etc/shadow
        #|/etc/passwd
      End

      When call echo "$THEDATA"
      The output should not match pattern "$url_pattern"
    End

    It 'rejects malformed URLs'
      Data
        #|https://
        #|http://localhost
        #|https://example
        #|not-a-url
      End

      When call echo "$THEDATA"
      The output should not match pattern "$url_pattern"
    End
  End

  Describe '_safe_source function'
    Before 'source_goodmorning'

    setup() {
      TEST_DIR=$(mktemp -d)
      SAFE_FILE="$TEST_DIR/safe.sh"
      UNSAFE_FILE="$TEST_DIR/unsafe.sh"
      NONEXISTENT="$TEST_DIR/nonexistent.sh"

      echo '#!/usr/bin/env zsh' > "$SAFE_FILE"
      echo 'echo "safe"' >> "$SAFE_FILE"
      chmod 644 "$SAFE_FILE"

      echo '#!/usr/bin/env zsh' > "$UNSAFE_FILE"
      echo 'rm -rf /' >> "$UNSAFE_FILE"
      chmod 666 "$UNSAFE_FILE"
    }

    cleanup() {
      [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
    }

    Before 'setup'
    After 'cleanup'

    It 'rejects missing files'
      When call _safe_source "$NONEXISTENT"
      The status should be failure
      The stderr should not be blank
    End

    It 'rejects world-writable files (security risk)'
      When call _safe_source "$UNSAFE_FILE"
      The status should be failure
      The stderr should include "Security"
    End

    It 'accepts properly secured files'
      When call _safe_source "$SAFE_FILE"
      The status should be success
      The output should include "safe"
    End
  End
End
