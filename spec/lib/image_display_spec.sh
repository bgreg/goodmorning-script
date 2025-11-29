#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'lib/daily_content.sh - iTerm2 Image Display'
  Before 'source_goodmorning'

  Include "$SHELLSPEC_PROJECT_ROOT/spec/support/image_helpers.sh"

  Describe '_iterm_can_display_images'
    It 'returns true for iTerm.app'
      export TERM_PROGRAM="iTerm.app"
      When call _iterm_can_display_images
      The status should be success
      unset TERM_PROGRAM
    End

    It 'returns true for LC_TERMINAL=iTerm2'
      export LC_TERMINAL="iTerm2"
      When call _iterm_can_display_images
      The status should be success
      unset LC_TERMINAL
    End

    It 'returns false for other terminals'
      export TERM_PROGRAM="Apple_Terminal"
      export LC_TERMINAL=""
      When call _iterm_can_display_images
      The status should be failure
      unset TERM_PROGRAM LC_TERMINAL
    End
  End

  Describe '_generate_iterm_image_sequence'
    setup_test_image() {
      TEST_IMAGE=$(create_test_image "/tmp/shellspec_test_image_$$.png")
    }

    cleanup_test_image() {
      rm -f "$TEST_IMAGE" 2>/dev/null
    }

    Before 'setup_test_image'
    After 'cleanup_test_image'

    It 'generates escape sequence for valid image'
      When call _generate_iterm_image_sequence "$TEST_IMAGE"
      The status should be success
      The output should start with $'\033]1337;File='
      The output should include 'inline=1'
    End

    It 'fails for nonexistent file'
      When call _generate_iterm_image_sequence "/nonexistent/file.jpg"
      The status should be failure
    End

    It 'includes size parameter'
      When call _generate_iterm_image_sequence "$TEST_IMAGE"
      The output should match pattern '*size=*'
    End

    It 'ends with BEL terminator (hex check)'
      check_bel_terminator() {
        local seq=$(_generate_iterm_image_sequence "$TEST_IMAGE")
        local last_byte=$(printf '%s' "$seq" | tail -c 1 | xxd -p)
        [[ "$last_byte" == "07" ]]
      }
      When call check_bel_terminator
      The status should be success
    End

    It 'has no embedded newlines in base64'
      check_no_newlines() {
        local seq=$(_generate_iterm_image_sequence "$TEST_IMAGE")
        local payload="${seq#*:}"
        payload="${payload%$'\a'*}"
        [[ "$payload" != *$'\n'* ]]
      }
      When call check_no_newlines
      The status should be success
    End

    It 'contains valid base64 that decodes to image'
      check_valid_payload() {
        local seq=$(_generate_iterm_image_sequence "$TEST_IMAGE")
        local payload="${seq#*:}"
        payload="${payload%$'\a'*}"
        local temp_file=$(mktemp)
        printf '%s' "$payload" | base64 -d > "$temp_file" 2>/dev/null
        local result=$?
        file "$temp_file" | grep -qE 'image|PNG|data'
        local file_result=$?
        rm -f "$temp_file"
        [[ $result -eq 0 ]] && [[ $file_result -eq 0 ]]
      }
      When call check_valid_payload
      The status should be success
    End

    It 'has exactly one OSC marker'
      check_single_osc() {
        local seq=$(_generate_iterm_image_sequence "$TEST_IMAGE")
        local count=$(count_osc_markers "$seq")
        [[ "$count" -eq 1 ]]
      }
      When call check_single_osc
      The status should be success
    End

    It 'has exactly one BEL terminator'
      check_single_bel() {
        local seq=$(_generate_iterm_image_sequence "$TEST_IMAGE")
        local count=$(count_bel_terminators "$seq")
        [[ "$count" -eq 1 ]]
      }
      When call check_single_bel
      The status should be success
    End

    It 'has correct boundary bytes (ESC ] at start, BEL at end)'
      check_boundaries() {
        local seq=$(_generate_iterm_image_sequence "$TEST_IMAGE")
        validate_sequence_boundaries "$seq"
      }
      When call check_boundaries
      The status should be success
    End

    It 'base64 payload contains only valid characters'
      check_base64_charset() {
        local seq=$(_generate_iterm_image_sequence "$TEST_IMAGE")
        validate_base64_charset "$seq"
      }
      When call check_base64_charset
      The status should be success
    End

    It 'size parameter matches actual file size'
      check_size_param() {
        local seq=$(_generate_iterm_image_sequence "$TEST_IMAGE")
        validate_size_parameter_matches_file "$seq" "$TEST_IMAGE"
      }
      When call check_size_param
      The status should be success
    End

    It 'round-trip decode matches original file'
      check_round_trip() {
        local seq=$(_generate_iterm_image_sequence "$TEST_IMAGE")
        validate_round_trip_integrity "$seq" "$TEST_IMAGE"
      }
      When call check_round_trip
      The status should be success
    End

    It 'has single colon separator between params and data'
      check_colon_separator() {
        local seq=$(_generate_iterm_image_sequence "$TEST_IMAGE")
        validate_single_colon_separator "$seq"
      }
      When call check_colon_separator
      The status should be success
    End

    It 'contains width parameter'
      check_width_param() {
        local seq=$(_generate_iterm_image_sequence "$TEST_IMAGE")
        [[ "$seq" == *"width="* ]]
      }
      When call check_width_param
      The status should be success
    End

    It 'contains preserveAspectRatio parameter'
      check_aspect_ratio_param() {
        local seq=$(_generate_iterm_image_sequence "$TEST_IMAGE")
        [[ "$seq" == *"preserveAspectRatio="* ]]
      }
      When call check_aspect_ratio_param
      The status should be success
    End

    It 'produces identical output on repeated calls (idempotency)'
      check_idempotency() {
        local seq1=$(_generate_iterm_image_sequence "$TEST_IMAGE")
        local seq2=$(_generate_iterm_image_sequence "$TEST_IMAGE")
        [[ "$seq1" == "$seq2" ]]
      }
      When call check_idempotency
      The status should be success
    End
  End

  Describe '_display_image_iterm with capture mode'
    setup() {
      TEST_IMAGE=$(create_test_image "/tmp/shellspec_capture_test_$$.png")
      mock_iterm_environment
    }

    cleanup() {
      rm -f "$TEST_IMAGE" 2>/dev/null
      unmock_iterm_environment
    }

    Before 'setup'
    After 'cleanup'

    It 'outputs escape sequence in capture mode'
      export GOODMORNING_IMAGE_CAPTURE_MODE=1
      When call _display_image_iterm "$TEST_IMAGE"
      The status should be success
      The output should start with $'\033]1337;File='
      unset GOODMORNING_IMAGE_CAPTURE_MODE
    End

    It 'fails for missing file'
      export GOODMORNING_IMAGE_CAPTURE_MODE=1
      When call _display_image_iterm "/nonexistent/image.jpg"
      The status should be failure
      unset GOODMORNING_IMAGE_CAPTURE_MODE
    End

    It 'fails when not in iTerm environment'
      unmock_iterm_environment
      export TERM_PROGRAM="Apple_Terminal"
      export GOODMORNING_IMAGE_CAPTURE_MODE=1
      When call _display_image_iterm "$TEST_IMAGE"
      The status should be failure
      unset GOODMORNING_IMAGE_CAPTURE_MODE TERM_PROGRAM
    End
  End

  Describe '_tty_is_available'
    It 'returns success or failure based on tty'
      tty_check() {
        _tty_is_available
        local exit_code=$?
        [[ $exit_code -eq 0 || $exit_code -eq 1 ]]
      }
      When call tty_check
      The status should be success
    End
  End
End

Describe 'Image test helpers'
  Include "$SHELLSPEC_PROJECT_ROOT/spec/support/image_helpers.sh"

  Describe 'create_test_image'
    It 'creates a valid image file'
      check_creates_image() {
        local test_file="/tmp/helper_test_$$.png"
        create_test_image "$test_file" >/dev/null
        [[ -f "$test_file" ]] && file "$test_file" | grep -qE 'PNG|image|data'
        local result=$?
        rm -f "$test_file"
        return $result
      }
      When call check_creates_image
      The status should be success
    End
  End

  Describe 'validate_iterm_sequence_structure'
    It 'accepts valid sequence'
      valid_seq=$'\033]1337;File=inline=1:YWJjZA==\a'
      When call validate_iterm_sequence_structure "$valid_seq"
      The status should be success
    End

    It 'rejects sequence without OSC prefix'
      invalid_seq='File=inline=1:YWJjZA=='
      When call validate_iterm_sequence_structure "$invalid_seq"
      The status should be failure
    End

    It 'rejects sequence without inline parameter'
      invalid_seq=$'\033]1337;File=:YWJjZA==\a'
      When call validate_iterm_sequence_structure "$invalid_seq"
      The status should be failure
    End
  End

  Describe 'validate_iterm_sequence_terminator'
    It 'accepts BEL terminated sequence'
      seq=$'\033]1337;File=inline=1:abc\a'
      When call validate_iterm_sequence_terminator "$seq"
      The status should be success
    End

    It 'rejects sequence without BEL'
      seq=$'\033]1337;File=inline=1:abc'
      When call validate_iterm_sequence_terminator "$seq"
      The status should be failure
    End
  End

  Describe 'extract_base64_from_sequence'
    It 'extracts base64 payload'
      seq=$'\033]1337;File=inline=1:SGVsbG8gV29ybGQ=\a'
      When call extract_base64_from_sequence "$seq"
      The output should equal 'SGVsbG8gV29ybGQ='
    End
  End
End
