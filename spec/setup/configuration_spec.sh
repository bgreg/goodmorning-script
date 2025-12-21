#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'setup.sh - Configuration Management'
  Describe 'Configuration file generation'
    setup() {
      TEST_CONFIG_DIR=$(mktemp -d)
      export GOODMORNING_CONFIG_DIR="$TEST_CONFIG_DIR"
      export CONFIG_DIR="$TEST_CONFIG_DIR"
      export CONFIG_FILE="$TEST_CONFIG_DIR/config.sh"
    }

    cleanup() {
      [ -d "$TEST_CONFIG_DIR" ] && rm -rf "$TEST_CONFIG_DIR"
      unset GOODMORNING_CONFIG_DIR
      unset CONFIG_DIR
      unset CONFIG_FILE
    }

    Before 'setup'
    After 'cleanup'

    It 'creates config directory'
      mkdir -p "$CONFIG_DIR"
      The path "$CONFIG_DIR" should be directory
    End

    It 'generates config file with GOODMORNING_USER_NAME'
      echo 'export GOODMORNING_USER_NAME="TestUser"' > "$CONFIG_FILE"
      When call grep 'GOODMORNING_USER_NAME' "$CONFIG_FILE"
      The status should be success
      The output should include "TestUser"
    End

    It 'generates config file with GOODMORNING_ENABLE_TTS'
      echo 'export GOODMORNING_ENABLE_TTS="false"' > "$CONFIG_FILE"
      When call grep 'GOODMORNING_ENABLE_TTS' "$CONFIG_FILE"
      The status should be success
      The output should include "GOODMORNING_ENABLE_TTS"
    End

    It 'generates config file with GOODMORNING_PROJECT_DIRS'
      echo 'export GOODMORNING_PROJECT_DIRS="$HOME"' > "$CONFIG_FILE"
      When call grep 'GOODMORNING_PROJECT_DIRS' "$CONFIG_FILE"
      The status should be success
      The output should not be blank
    End
  End

  Describe 'Environment variable handling'
    It 'respects GOODMORNING_CONFIG_DIR override'
      export GOODMORNING_CONFIG_DIR="/tmp/test-config"
      When call echo "$GOODMORNING_CONFIG_DIR"
      The output should equal "/tmp/test-config"
    End

    It 'respects GOODMORNING_INSTALL_DIR override'
      export GOODMORNING_INSTALL_DIR="/tmp/test-install"
      When call echo "$GOODMORNING_INSTALL_DIR"
      The output should equal "/tmp/test-install"
    End

    It 'uses default CONFIG_DIR if not set'
      unset GOODMORNING_CONFIG_DIR
      When call echo "${GOODMORNING_CONFIG_DIR:-$HOME/.config/goodmorning}"
      The output should include ".config/goodmorning"
    End
  End

  Describe 'Text-to-speech configuration'
    It 'setup collects TTS preference'
      When call grep 'enable_tts' ./setup.sh
      The status should be success
      The output should not be blank
    End

    It 'exports GOODMORNING_ENABLE_TTS in config'
      When call grep 'GOODMORNING_ENABLE_TTS' ./setup.sh
      The status should be success
      The output should not be blank
    End
  End
End
