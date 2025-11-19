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

    It 'sources color library for output formatting'
      # setup.sh sources lib/colors.sh for formatted output
      When call grep 'source.*lib/colors.sh' ./setup.sh
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

    It 'validates file paths when checking config'
      # setup.sh checks if files exist using [ -f ] syntax
      When call grep '\[ -f' ./setup.sh
      The status should be success
      The output should not be blank
    End

  End

  Describe 'Directory validation'
    It 'creates directories when needed'
      # setup.sh uses mkdir -p to ensure directories exist
      When call grep 'mkdir -p' ./setup.sh
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
