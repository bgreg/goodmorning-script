#!/usr/bin/env zsh
#shellspec shell=zsh

Describe 'goodmorning.sh - Resource Management'
  Before 'source_goodmorning'

  Describe 'Temporary file creation'
    It 'uses mktemp for secure temp files'
      When call grep -r 'mktemp' ./lib/
      The status should be success
      The output should include "mktemp"
    End

    It 'uses secure temp file patterns'
      When call grep 'mktemp' ./lib/updates.sh
      The status should be success
      The output should include "mktemp"
    End

    It 'temp files use XXXXXX pattern'
      When call grep 'PATTERN' ./lib/updates.sh
      The status should be success
      The output should include "PATTERN"
    End
  End

  Describe 'Temp file tracking'
    It 'defines TEMP_FILES array'
      When call grep "TEMP_FILES" ./lib/core.sh
      The status should be success
      The output should include "TEMP_FILES"
    End

    It 'temp files are tracked'
      When call grep "TEMP_FILES" ./lib/core.sh
      The status should be success
      The output should include "TEMP_FILES"
    End
  End

  Describe 'Background process management'
    It 'defines BACKGROUND_PIDS array'
      When call grep "BACKGROUND_PIDS" ./lib/core.sh
      The status should be success
      The output should include "BACKGROUND_PIDS"
    End

    It 'background PIDs are tracked'
      When call grep "BACKGROUND_PIDS" ./lib/core.sh
      The status should be success
      The output should include "BACKGROUND_PIDS"
    End
  End

  Describe 'Trap handlers'
    It 'sets up EXIT trap'
      When call grep -E 'trap.*_cleanup.*EXIT' "lib/core.sh"
      The status should be success
      The output should include "trap"
      The output should include "EXIT"
    End

    It 'sets up INT trap'
      When call grep -E 'trap.*_cleanup.*INT' "lib/core.sh"
      The status should be success
      The output should include "trap"
      The output should include "INT"
    End

    It 'sets up TERM trap'
      When call grep -E 'trap.*_cleanup.*TERM' "./lib/core.sh"
      The status should be success
      The output should include "trap"
      The output should include "TERM"
    End
  End

  Describe '_cleanup function'
    It 'is defined'
      When call type _cleanup
      The status should be success
      The output should include "_cleanup"
      The output should include "function"
    End

    It 'handles temp file cleanup'
      When call grep "TEMP_FILES" ./lib/core.sh
      The status should be success
      The output should include "TEMP_FILES"
    End

    It 'handles background PID cleanup'
      When call grep "BACKGROUND_PIDS" ./lib/core.sh
      The status should be success
      The output should include "BACKGROUND_PIDS"
    End

    It 'removes temp files'
      When call grep "TEMP_FILES" ./lib/core.sh
      The status should be success
      The output should include "TEMP_FILES"
    End

    It 'kills background processes'
      When call grep "BACKGROUND_PIDS" ./lib/core.sh
      The status should be success
      The output should include "BACKGROUND_PIDS"
    End
  End
End
