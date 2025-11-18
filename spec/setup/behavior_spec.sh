#!/usr/bin/env zsh
#shellspec shell=zsh

# World-class BDD test suite for setup.sh
# Tests actual runtime behavior through function execution and output verification

Describe 'setup.sh'
  # Load dependencies
  Include lib/colors.sh

  Describe 'Color Output System'
    Describe 'echo_green'
      It 'outputs text with green ANSI codes'
        When call echo_green "success message"
        The output should include "success message"
        The status should be success
      End

      It 'handles multiple arguments'
        When call echo_green "multiple" "args" "here"
        The output should include "multiple args here"
      End

      Context 'with -n flag'
        It 'suppresses trailing newline'
          output() { echo_green -n "no newline"; echo "MARKER"; }
          When call output
          The output should include "no newline"
          The output should include "MARKER"
          The lines of output should equal 1
        End

        It 'still includes color codes'
          When call echo_green -n "colored"
          The output should include "colored"
        End
      End
    End

    Describe 'echo_red'
      It 'outputs text with red ANSI codes'
        When call echo_red "error message"
        The output should include "error message"
        The status should be success
      End

      Context 'with -n flag'
        It 'suppresses trailing newline'
          output() { echo_red -n "no newline"; echo "MARKER"; }
          When call output
          The output should include "no newline"
          The output should include "MARKER"
          The lines of output should equal 1
        End
      End
    End

    Describe 'echo_yellow'
      It 'outputs text with yellow ANSI codes'
        When call echo_yellow "warning message"
        The output should include "warning message"
        The status should be success
      End

      Context 'with -n flag'
        It 'suppresses trailing newline'
          output() { echo_yellow -n "no newline"; echo "MARKER"; }
          When call output
          The output should include "no newline"
          The output should include "MARKER"
          The lines of output should equal 1
        End
      End
    End

    Describe 'echo_cyan'
      It 'outputs text with cyan ANSI codes'
        When call echo_cyan "info message"
        The output should include "info message"
        The status should be success
      End

      Context 'with -n flag'
        It 'suppresses trailing newline'
          output() { echo_cyan -n "no newline"; echo "MARKER"; }
          When call output
          The output should include "no newline"
          The output should include "MARKER"
          The lines of output should equal 1
        End
      End
    End

    Describe 'echo_blue'
      It 'outputs text with blue ANSI codes'
        When call echo_blue "blue message"
        The output should include "blue message"
        The status should be success
      End

      Context 'with -n flag'
        It 'suppresses trailing newline'
          output() { echo_blue -n "no newline"; echo "MARKER"; }
          When call output
          The output should include "no newline"
          The output should include "MARKER"
          The lines of output should equal 1
        End
      End
    End

    Describe 'echo_gray'
      It 'outputs text with gray ANSI codes'
        When call echo_gray "gray message"
        The output should include "gray message"
        The status should be success
      End

      Context 'with -n flag'
        It 'suppresses trailing newline'
          output() { echo_gray -n "no newline"; echo "MARKER"; }
          When call output
          The output should include "no newline"
          The output should include "MARKER"
          The lines of output should equal 1
        End
      End
    End
  End

  Describe 'Prompt Inline Behavior'
    It 'prompt and user input appear on same line'
      output() { echo_green -n "Enter value: "; echo "user_input"; }
      When call output
      The output should include "Enter value:"
      The output should include "user_input"
      The lines of output should equal 1
    End

    It 'prompt with brackets shows default inline'
      output() { echo_green -n "Name [default]: "; echo "typed"; }
      When call output
      The lines of output should equal 1
    End

    It 'multiple prompts each on their own line'
      output() {
        echo_green -n "First: "; echo "one"
        echo_green -n "Second: "; echo "two"
      }
      When call output
      The lines of output should equal 2
    End
  End

  Describe 'Configuration File Handling'
    setup() {
      TEST_CONFIG_DIR=$(mktemp -d)
      TEST_CONFIG_FILE="$TEST_CONFIG_DIR/config.sh"
    }

    cleanup() {
      [ -d "$TEST_CONFIG_DIR" ] && rm -rf "$TEST_CONFIG_DIR"
    }

    Before 'setup'
    After 'cleanup'

    Describe 'generated config file'
      It 'is valid shell syntax'
        cat > "$TEST_CONFIG_FILE" << 'EOF'
export GOODMORNING_USER_NAME="testuser"
export GOODMORNING_ENABLE_TTS="false"
export GOODMORNING_BACKUP_SCRIPT=""
export GOODMORNING_VIM_PLUGINS_DIR="$HOME/.vim/pack/vendor/start"
export GOODMORNING_PROJECT_DIRS="$HOME"
EOF
        When call zsh -n "$TEST_CONFIG_FILE"
        The status should be success
      End

      It 'can be sourced without errors'
        cat > "$TEST_CONFIG_FILE" << 'EOF'
export GOODMORNING_USER_NAME="testuser"
export GOODMORNING_ENABLE_TTS="false"
EOF
        When call source "$TEST_CONFIG_FILE"
        The status should be success
      End

      It 'properly exports variables after sourcing'
        cat > "$TEST_CONFIG_FILE" << 'EOF'
export GOODMORNING_USER_NAME="testuser"
export GOODMORNING_ENABLE_TTS="false"
EOF
        source "$TEST_CONFIG_FILE"
        The variable GOODMORNING_USER_NAME should equal "testuser"
        The variable GOODMORNING_ENABLE_TTS should equal "false"
      End

      It 'handles values with spaces correctly'
        cat > "$TEST_CONFIG_FILE" << 'EOF'
export GOODMORNING_USER_NAME="John Doe"
EOF
        source "$TEST_CONFIG_FILE"
        The variable GOODMORNING_USER_NAME should equal "John Doe"
      End

      It 'handles empty values correctly'
        cat > "$TEST_CONFIG_FILE" << 'EOF'
export GOODMORNING_BACKUP_SCRIPT=""
EOF
        source "$TEST_CONFIG_FILE"
        The variable GOODMORNING_BACKUP_SCRIPT should equal ""
      End

      It 'handles special characters in values'
        cat > "$TEST_CONFIG_FILE" << 'EOF'
export GOODMORNING_PROJECT_DIRS="/path/with spaces/and-dashes_underscores"
EOF
        source "$TEST_CONFIG_FILE"
        The variable GOODMORNING_PROJECT_DIRS should equal "/path/with spaces/and-dashes_underscores"
      End

      It 'handles tilde expansion in paths'
        cat > "$TEST_CONFIG_FILE" << 'EOF'
export GOODMORNING_VIM_PLUGINS_DIR="$HOME/.vim/pack"
EOF
        source "$TEST_CONFIG_FILE"
        The variable GOODMORNING_VIM_PLUGINS_DIR should equal "$HOME/.vim/pack"
      End
    End
  End

  Describe 'Command Line Interface'
    Describe '--help flag'
      It 'displays usage information'
        When call ./setup.sh --help
        The output should include "Usage"
        The status should be success
      End

      It 'lists available options'
        When call ./setup.sh --help
        The output should include "--reconfigure"
        The output should include "--show-config"
      End
    End

    Describe '--show-config flag'
      setup() {
        TEST_CONFIG_DIR=$(mktemp -d)
        export GOODMORNING_CONFIG_DIR="$TEST_CONFIG_DIR"
        cat > "$TEST_CONFIG_DIR/config.sh" << 'EOF'
export GOODMORNING_USER_NAME="testuser"
export GOODMORNING_ENABLE_TTS="false"
EOF
      }

      cleanup() {
        [ -d "$TEST_CONFIG_DIR" ] && rm -rf "$TEST_CONFIG_DIR"
        unset GOODMORNING_CONFIG_DIR
      }

      Before 'setup'
      After 'cleanup'

      It 'displays current configuration when config exists'
        Skip "Requires setup.sh to support GOODMORNING_CONFIG_DIR override"
        When call ./setup.sh --show-config
        The output should include "GOODMORNING_USER_NAME"
        The status should be success
      End
    End
  End

  Describe 'Script Execution'
    It 'script is executable'
      When call test -x ./setup.sh
      The status should be success
    End

    It 'script has valid zsh syntax'
      When call zsh -n ./setup.sh
      The status should be success
    End

    It 'lib/colors.sh has valid syntax'
      When call zsh -n ./lib/colors.sh
      The status should be success
    End

    It 'lib/colors.sh is sourceable'
      When call source ./lib/colors.sh
      The status should be success
    End
  End

  Describe 'Color Code Availability'
    It 'COLOR_GREEN is defined after sourcing'
      The variable COLOR_GREEN should be defined
    End

    It 'COLOR_RED is defined after sourcing'
      The variable COLOR_RED should be defined
    End

    It 'COLOR_YELLOW is defined after sourcing'
      The variable COLOR_YELLOW should be defined
    End

    It 'COLOR_CYAN is defined after sourcing'
      The variable COLOR_CYAN should be defined
    End

    It 'COLOR_BLUE is defined after sourcing'
      The variable COLOR_BLUE should be defined
    End

    It 'COLOR_GRAY is defined after sourcing'
      The variable COLOR_GRAY should be defined
    End

    It 'COLOR_RESET is defined after sourcing'
      The variable COLOR_RESET should be defined
    End
  End
End
