#!/usr/bin/env zsh
#shellspec shell=zsh

###############################################################################
# Utilities Library Tests
#
# Tests for lib/utilities.sh functions
###############################################################################

Describe 'lib/utilities.sh - Utility Functions'
  Before 'source_goodmorning'

  Describe 'jq_extract function'
    It 'is defined'
      When call type jq_extract
      The status should be success
      The output should include "function"
    End

    It 'extracts simple JSON field'
      json='{"name":"test","value":42}'
      When call jq_extract "$json" '.name'
      The output should equal "test"
    End

    It 'extracts nested JSON field'
      json='{"outer":{"inner":"deep"}}'
      When call jq_extract "$json" '.outer.inner'
      The output should equal "deep"
    End

    It 'returns empty for missing field'
      json='{"name":"test"}'
      When call jq_extract "$json" '.missing'
      The output should equal ""
    End

    It 'returns empty for null field'
      json='{"name":null}'
      When call jq_extract "$json" '.name'
      The output should equal ""
    End

    It 'extracts array element'
      json='[{"id":1},{"id":2}]'
      When call jq_extract "$json" '.[0].id'
      The output should equal "1"
    End

    # CRITICAL REGRESSION TEST: PATH variable must not be corrupted
    # Bug: Using "path" as parameter name overwrites $PATH in zsh
    It 'does not corrupt PATH environment variable'
      original_path="$PATH"
      json='{"foo":"bar"}'
      jq_extract "$json" '.foo' >/dev/null
      The variable PATH should equal "$original_path"
    End

    # Verify commands still work after jq_extract (PATH intact)
    It 'allows commands to execute after extraction'
      json='{"test":"value"}'
      jq_extract "$json" '.test' >/dev/null
      When call which ls
      The status should be success
      The output should be present
    End
  End

  Describe 'fetch_url function'
    It 'is defined'
      When call type fetch_url
      The status should be success
      The output should include "function"
    End
  End

  Describe 'require_non_empty function'
    It 'is defined'
      When call type require_non_empty
      The status should be success
      The output should include "function"
    End

    It 'returns success for non-empty string'
      When call require_non_empty "hello"
      The status should be success
    End

    It 'returns failure for empty string'
      When call require_non_empty ""
      The status should be failure
    End

    # Note: "null" as a literal string is non-empty, so this passes
    # The safe_display function handles JSON null translation
  End

  Describe 'random_in_range function'
    It 'is defined'
      When call type random_in_range
      The status should be success
      The output should include "function"
    End

    It 'returns number within range'
      When call random_in_range 10
      The output should be present
      The status should be success
    End
  End

  Describe 'random_array_element function'
    It 'is defined'
      When call type random_array_element
      The status should be success
      The output should include "function"
    End

    It 'selects item from array'
      When call random_array_element "one" "two" "three"
      The output should be present
    End
  End

  Describe 'to_title_case function'
    It 'is defined'
      When call type to_title_case
      The status should be success
      The output should include "function"
    End

    It 'converts to title case'
      When call to_title_case "hello world"
      The output should equal "Hello World"
    End
  End

  Describe 'safe_display function'
    It 'is defined'
      When call type safe_display
      The status should be success
      The output should include "function"
    End

    It 'returns value for valid input'
      When call safe_display "hello" "default"
      The output should equal "hello"
    End

    It 'returns fallback for empty input'
      When call safe_display "" "default"
      The output should equal "default"
    End

    It 'returns fallback for null input'
      When call safe_display "null" "default"
      The output should equal "default"
    End

    It 'returns N/A when no fallback specified'
      When call safe_display ""
      The output should equal "N/A"
    End
  End
End
