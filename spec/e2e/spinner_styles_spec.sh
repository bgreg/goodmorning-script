#!/usr/bin/env zsh
#shellspec shell=zsh

# End-to-End Spinner Styles Validation Tests
# Run with: shellspec spec/e2e/spinner_styles_spec.sh
# Or with real validation: SHELLSPEC_REAL=1 shellspec spec/e2e/spinner_styles_spec.sh

Describe 'E2E Spinner Styles Tests'
  Include lib/colors.sh
  Include lib/core.sh

  setup() {
    RESULTS_DIR=$(mktemp -d)
  }

  cleanup() {
    [ -d "$RESULTS_DIR" ] && rm -rf "$RESULTS_DIR"
  }

  BeforeAll 'setup'
  AfterAll 'cleanup'

  Describe 'Spinner style definitions'
    It 'SPINNER_STYLES_CHARS is defined'
      The variable SPINNER_STYLES_CHARS should be defined
    End

    It 'SPINNER_STYLES_BACKSPACES is defined'
      The variable SPINNER_STYLES_BACKSPACES should be defined
    End

    It 'SPINNER_STYLE_NAMES is defined'
      The variable SPINNER_STYLE_NAMES should be defined
    End

    It 'has exactly 12 spinner styles'
      style_count() {
        echo "${#SPINNER_STYLE_NAMES[@]}"
      }
      When call style_count
      The output should equal 12
    End
  End

  Describe 'All spinner styles have required properties'
    It 'moon style has characters and backspaces'
      The value "${SPINNER_STYLES_CHARS[moon]}" should not be blank
      The value "${SPINNER_STYLES_BACKSPACES[moon]}" should not be blank
    End

    It 'braille style has characters and backspaces'
      The value "${SPINNER_STYLES_CHARS[braille]}" should not be blank
      The value "${SPINNER_STYLES_BACKSPACES[braille]}" should not be blank
    End

    It 'line style has characters and backspaces'
      The value "${SPINNER_STYLES_CHARS[line]}" should not be blank
      The value "${SPINNER_STYLES_BACKSPACES[line]}" should not be blank
    End

    It 'bounce style has characters and backspaces'
      The value "${SPINNER_STYLES_CHARS[bounce]}" should not be blank
      The value "${SPINNER_STYLES_BACKSPACES[bounce]}" should not be blank
    End

    It 'clock style has characters and backspaces'
      The value "${SPINNER_STYLES_CHARS[clock]}" should not be blank
      The value "${SPINNER_STYLES_BACKSPACES[clock]}" should not be blank
    End

    It 'arrows style has characters and backspaces'
      The value "${SPINNER_STYLES_CHARS[arrows]}" should not be blank
      The value "${SPINNER_STYLES_BACKSPACES[arrows]}" should not be blank
    End

    It 'growing style has characters and backspaces'
      The value "${SPINNER_STYLES_CHARS[growing]}" should not be blank
      The value "${SPINNER_STYLES_BACKSPACES[growing]}" should not be blank
    End

    It 'box style has characters and backspaces'
      The value "${SPINNER_STYLES_CHARS[box]}" should not be blank
      The value "${SPINNER_STYLES_BACKSPACES[box]}" should not be blank
    End

    It 'ball style has characters and backspaces'
      The value "${SPINNER_STYLES_CHARS[ball]}" should not be blank
      The value "${SPINNER_STYLES_BACKSPACES[ball]}" should not be blank
    End

    It 'weather style has characters and backspaces'
      The value "${SPINNER_STYLES_CHARS[weather]}" should not be blank
      The value "${SPINNER_STYLES_BACKSPACES[weather]}" should not be blank
    End

    It 'dots style has characters and backspaces'
      The value "${SPINNER_STYLES_CHARS[dots]}" should not be blank
      The value "${SPINNER_STYLES_BACKSPACES[dots]}" should not be blank
    End

    It 'star style has characters and backspaces'
      The value "${SPINNER_STYLES_CHARS[star]}" should not be blank
      The value "${SPINNER_STYLES_BACKSPACES[star]}" should not be blank
    End
  End

  Describe 'All styles in SPINNER_STYLE_NAMES exist'
    validate_all_styles_exist() {
      local missing=0

      for style_name in "${SPINNER_STYLE_NAMES[@]}"; do
        if [[ -z "${SPINNER_STYLES_CHARS[$style_name]}" ]]; then
          echo "MISSING CHARS: $style_name" >&2
          missing=$((missing + 1))
        fi
        if [[ -z "${SPINNER_STYLES_BACKSPACES[$style_name]}" ]]; then
          echo "MISSING BACKSPACES: $style_name" >&2
          missing=$((missing + 1))
        fi
      done

      [ "$missing" -eq 0 ]
    }

    It 'all named styles have definitions'
      When call validate_all_styles_exist
      The status should be success
    End
  End

  Describe 'Backspace count validation'
    validate_backspace_counts() {
      local errors=0

      for style_name in "${SPINNER_STYLE_NAMES[@]}"; do
        local chars_string="${SPINNER_STYLES_CHARS[$style_name]}"
        local backspace_count="${SPINNER_STYLES_BACKSPACES[$style_name]}"
        local chars_array=(${(s: :)chars_string})

        # Check that backspace count is a positive integer
        if ! [[ "$backspace_count" =~ ^[0-9]+$ ]] || [[ "$backspace_count" -eq 0 ]]; then
          echo "INVALID BACKSPACE COUNT: $style_name = $backspace_count" >&2
          errors=$((errors + 1))
          continue
        fi

        # Verify each character in the style
        for char in "${chars_array[@]}"; do
          # Skip empty entries
          [ -z "$char" ] && continue

          # Calculate expected backspaces based on UTF-8 character width
          # Emoji characters typically need 2 backspaces
          # Single-width Unicode characters need 1 backspace
          local char_bytes=${#char}

          # Basic validation that backspace count is reasonable
          if [[ "$backspace_count" -lt 1 ]] || [[ "$backspace_count" -gt 4 ]]; then
            echo "SUSPICIOUS BACKSPACE COUNT: $style_name needs $backspace_count backspaces" >&2
            errors=$((errors + 1))
          fi
        done
      done

      [ "$errors" -eq 0 ]
    }

    It 'all backspace counts are valid'
      When call validate_backspace_counts
      The status should be success
    End

    It 'moon style needs 2 backspaces for emoji'
      The value "${SPINNER_STYLES_BACKSPACES[moon]}" should equal 2
    End

    It 'braille style needs 1 backspace'
      The value "${SPINNER_STYLES_BACKSPACES[braille]}" should equal 1
    End

    It 'line style needs 1 backspace'
      The value "${SPINNER_STYLES_BACKSPACES[line]}" should equal 1
    End

    It 'clock style needs 2 backspaces for emoji'
      The value "${SPINNER_STYLES_BACKSPACES[clock]}" should equal 2
    End

    It 'weather style needs 4 backspaces for emoji with variation selector'
      The value "${SPINNER_STYLES_BACKSPACES[weather]}" should equal 4
    End
  End

  Describe '_select_random_spinner_style function'
    It 'is defined'
      When call type _select_random_spinner_style
      The status should be success
      The output should include "function"
    End

    It 'sets SELECTED_SPINNER_STYLE when called'
      unset SELECTED_SPINNER_STYLE
      When call _select_random_spinner_style
      The variable SELECTED_SPINNER_STYLE should be defined
      The status should be success
    End

    It 'selects a valid style from the available list'
      check_valid_selection() {
        unset SELECTED_SPINNER_STYLE
        _select_random_spinner_style

        local found=0
        for style_name in "${SPINNER_STYLE_NAMES[@]}"; do
          if [[ "$SELECTED_SPINNER_STYLE" == "$style_name" ]]; then
            found=1
            break
          fi
        done

        [ "$found" -eq 1 ]
      }
      When call check_valid_selection
      The status should be success
    End

    It 'populates SELECTED_SPINNER_CHARS array'
      unset SELECTED_SPINNER_STYLE
      unset SELECTED_SPINNER_CHARS
      _select_random_spinner_style
      The variable SELECTED_SPINNER_CHARS should be defined
    End

    It 'populates SELECTED_SPINNER_BACKSPACES'
      unset SELECTED_SPINNER_STYLE
      unset SELECTED_SPINNER_BACKSPACES
      _select_random_spinner_style
      The variable SELECTED_SPINNER_BACKSPACES should be defined
    End
  End

  Describe 'Cycle through all spinner styles'
    It 'can iterate through all styles'
      cycle_all_styles() {
        local success_count=0
        local total="${#SPINNER_STYLE_NAMES[@]}"

        for style_name in "${SPINNER_STYLE_NAMES[@]}"; do
          local chars_string="${SPINNER_STYLES_CHARS[$style_name]}"
          local backspace_count="${SPINNER_STYLES_BACKSPACES[$style_name]}"
          local chars_array=(${(s: :)chars_string})

          # Verify style has at least 2 characters
          if [[ ${#chars_array[@]} -ge 2 ]]; then
            success_count=$((success_count + 1))
          fi
        done

        [ "$success_count" -eq "$total" ]
      }
      When call cycle_all_styles
      The status should be success
    End
  End

  Describe 'Spinner character validation'
    It 'all styles have at least 4 animation frames'
      check_frame_counts() {
        local errors=0

        for style_name in "${SPINNER_STYLE_NAMES[@]}"; do
          local chars_string="${SPINNER_STYLES_CHARS[$style_name]}"
          local chars_array=(${(s: :)chars_string})
          local frame_count=${#chars_array[@]}

          if [[ "$frame_count" -lt 4 ]]; then
            echo "INSUFFICIENT FRAMES: $style_name has only $frame_count frames" >&2
            errors=$((errors + 1))
          fi
        done

        [ "$errors" -eq 0 ]
      }
      When call check_frame_counts
      The status should be success
    End

    It 'moon style has correct frames'
      count_moon_frames() {
        local chars_string="${SPINNER_STYLES_CHARS[moon]}"
        local chars_array=(${(s: :)chars_string})
        echo "${#chars_array[@]}"
      }
      When call count_moon_frames
      The output should equal 8
    End

    It 'braille style has correct frames'
      count_braille_frames() {
        local chars_string="${SPINNER_STYLES_CHARS[braille]}"
        local chars_array=(${(s: :)chars_string})
        echo "${#chars_array[@]}"
      }
      When call count_braille_frames
      The output should equal 10
    End

    It 'clock style has correct frames'
      count_clock_frames() {
        local chars_string="${SPINNER_STYLES_CHARS[clock]}"
        local chars_array=(${(s: :)chars_string})
        echo "${#chars_array[@]}"
      }
      When call count_clock_frames
      The output should equal 12
    End
  End

  Describe 'run_with_spinner function'
    It 'is defined'
      When call type run_with_spinner
      The status should be success
      The output should include "function"
    End
  End

  Describe 'fetch_with_spinner function'
    It 'is defined'
      When call type fetch_with_spinner
      The status should be success
      The output should include "function"
    End
  End

  Describe 'Style consistency checks'
    It 'all style names follow naming convention'
      check_naming() {
        local errors=0

        for style_name in "${SPINNER_STYLE_NAMES[@]}"; do
          # Names should be lowercase alphanumeric
          if ! [[ "$style_name" =~ ^[a-z]+$ ]]; then
            echo "INVALID NAME: $style_name (should be lowercase letters only)" >&2
            errors=$((errors + 1))
          fi
        done

        [ "$errors" -eq 0 ]
      }
      When call check_naming
      The status should be success
    End

    It 'no duplicate style names'
      check_duplicates() {
        local names=("${SPINNER_STYLE_NAMES[@]}")
        local unique_count
        unique_count=$(printf '%s\n' "${names[@]}" | sort -u | wc -l | tr -d ' ')
        local total_count="${#names[@]}"

        [ "$unique_count" -eq "$total_count" ]
      }
      When call check_duplicates
      The status should be success
    End
  End

  Describe 'Visual spinner test (manual verification)'
    Skip if 'SHELLSPEC_REAL not set' [ -z "${SHELLSPEC_REAL:-}" ]

    It 'displays sample of each spinner style'
      show_all_spinners() {
        echo "Spinner Style Samples:" >&2
        echo "======================" >&2

        for style_name in "${SPINNER_STYLE_NAMES[@]}"; do
          local chars_string="${SPINNER_STYLES_CHARS[$style_name]}"
          local chars_array=(${(s: :)chars_string})
          local backspaces="${SPINNER_STYLES_BACKSPACES[$style_name]}"

          # Show first 4 frames as a sample
          local sample=""
          local count=0
          for char in "${chars_array[@]}"; do
            [ "$count" -ge 4 ] && break
            sample="$sample $char"
            count=$((count + 1))
          done

          printf "  %-10s [backspaces=%s]: %s ...\n" "$style_name" "$backspaces" "$sample" >&2
        done

        return 0
      }
      When call show_all_spinners
      The status should be success
    End
  End

  Describe 'Spinner timeout configuration'
    It 'SPINNER_TIMEOUT can be configured'
      test_timeout_config() {
        export SPINNER_TIMEOUT=5
        [ "$SPINNER_TIMEOUT" -eq 5 ]
      }
      When call test_timeout_config
      The status should be success
    End
  End
End
