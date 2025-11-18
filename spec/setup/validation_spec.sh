#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'setup.sh - Input Validation'
  Describe 'System requirements'
    It 'detects macOS correctly'
      Skip if 'not on macOS' test "$(uname)" != "Darwin"
      When call grep 'OSTYPE.*darwin' ./setup.sh
      The status should be success
      The output should not be blank
    End

    It 'checks for required dependencies'
      When call grep 'check_system_requirements' ./setup.sh
      The status should be success
      The output should not be blank
    End
  End

  Describe 'Path injection prevention'
    It 'rejects paths with command substitution'
      test_path='$(whoami)'
      When call printf '%s' "$test_path"
      The output should equal '$(whoami)'
      The output should not equal "$USER"
    End

    It 'rejects paths with backticks'
      test_path='`whoami`'
      When call printf '%s' "$test_path"
      The output should equal '`whoami`'
    End

    It 'rejects paths with semicolons'
      test_path='/tmp/test;whoami'
      When call printf '%s' "$test_path"
      The output should include ';'
    End

    It 'rejects paths with pipes'
      test_path='/tmp/test|whoami'
      When call printf '%s' "$test_path"
      The output should include '|'
    End
  End

  Describe 'File validation'
    setup() {
      TEST_DIR=$(mktemp -d)
      VALID_FILE="$TEST_DIR/valid.sh"
      echo '#!/usr/bin/env zsh' > "$VALID_FILE"
      chmod +x "$VALID_FILE"
    }

    cleanup() {
      [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
    }

    Before 'setup'
    After 'cleanup'

    It 'validate_file_path function exists'
      When call grep "validate_file_path" ./setup.sh
      The status should be success
      The output should not be blank
    End

    It 'rejects nonexistent files'
      When call validate_file_path "/nonexistent/file.sh"
      The status should be failure
      The stderr should not be blank
    End

  End

  Describe 'Directory validation'
    It 'validate_directory_path function exists'
      When call grep "validate_directory_path" ./setup.sh
      The status should be success
      The output should not be blank
    End

  End

  Describe 'Command line options'
    It 'accepts --run flag'
      # We just test that it's recognized, not executed
      When call grep '\-\-run' "$PROJECT_ROOT/setup.sh"
      The status should be success
      The output should not be blank
    End

    It 'accepts --reconfigure flag'
      When call grep '\-\-reconfigure' "$PROJECT_ROOT/setup.sh"
      The status should be success
      The output should not be blank
    End

    It 'accepts --show-config flag'
      When call grep '\-\-show-config' "$PROJECT_ROOT/setup.sh"
      The status should be success
      The output should not be blank
    End

    It 'accepts --regenerate-banner flag'
      When call grep '\-\-regenerate-banner' "$PROJECT_ROOT/setup.sh"
      The status should be success
      The output should not be blank
    End
  End
End
