#!/usr/bin/env zsh
#
# End-to-End Real API Test
#
# This test runs the actual goodmorning script and validates that all sections
# produce expected output. Since it hits real APIs, it only runs when --real
# flag is passed.
#
# Usage:
#   ./tests/test-e2e-real.sh          # Skips (no --real flag)
#   ./tests/test-e2e-real.sh --real   # Runs full e2e test
#
# This test prevents regressions like blank output from broken API parsing.

set -e

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Check for --real flag
REAL_MODE=false
for arg in "$@"; do
  if [[ "$arg" == "--real" ]]; then
    REAL_MODE=true
    break
  fi
done

if [[ "$REAL_MODE" != "true" ]]; then
  echo "${YELLOW}Skipping e2e real API tests (use --real flag to run)${NC}"
  echo ""
  echo "Usage: $0 --real"
  echo ""
  echo "This test hits real APIs and requires internet connectivity."
  exit 0
fi

echo "${CYAN}========================================${NC}"
echo "${CYAN}  E2E Real API Test Suite${NC}"
echo "${CYAN}========================================${NC}"
echo ""

# Capture script output
echo "Running goodmorning script..."
OUTPUT_FILE=$(mktemp)
CACHE_DIR="$PROJECT_ROOT/cache"

# Clear cache to force fresh API calls
rm -f "$CACHE_DIR"/*.json 2>/dev/null || true

# Run the script and capture output
env GOODMORNING_SHOW_SETUP_MESSAGES=false \
    GOODMORNING_FORCE_OFFLINE="" \
    "$PROJECT_ROOT/goodmorning.sh" > "$OUTPUT_FILE" 2>&1

echo "Script completed. Validating output..."
echo ""

# Test helper functions
test_section() {
  local name="$1"
  local pattern="$2"
  local description="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if grep -q "$pattern" "$OUTPUT_FILE"; then
    echo "${GREEN}✓${NC} $name: $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "${RED}✗${NC} $name: $description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

test_section_not_contains() {
  local name="$1"
  local pattern="$2"
  local description="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if ! grep -q "$pattern" "$OUTPUT_FILE"; then
    echo "${GREEN}✓${NC} $name: $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "${RED}✗${NC} $name: $description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

test_section_multiline() {
  local name="$1"
  local header_pattern="$2"
  local content_pattern="$3"
  local description="$4"

  TESTS_RUN=$((TESTS_RUN + 1))

  # Check if section header exists and has content after it
  if grep -A 20 "$header_pattern" "$OUTPUT_FILE" | grep -q "$content_pattern"; then
    echo "${GREEN}✓${NC} $name: $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "${RED}✗${NC} $name: $description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

echo "${CYAN}--- Section Output Tests ---${NC}"
echo ""

# Test 1: Banner shows
test_section "Banner" "Good Morning" "Banner displays greeting"

# Test 2: Weather shows actual data
test_section_multiline "Weather" "Weather:" "[0-9]°F\|[0-9]°C" "Weather shows temperature"

# Test 3: History section has content
test_section_multiline "History" "On This Day" "•.*[0-9]" "History shows dated events"

# Test 4: Tech versions show
test_section "Tech Versions" "Ruby.*v[0-9]" "Tech versions show Ruby version"

# Test 5: Country of the Day has actual content (not blank)
test_section_multiline "Country" "Country of the Day" "🏛️.*Capital:" "Country shows capital city"
test_section_multiline "Country" "Country of the Day" "Population:.*[0-9]" "Country shows population"

# Test 6: Word of the Day has actual word (not "Word of the Day" as the word)
test_section_not_contains "Word Content" "📖.*Word of the Day.*N/A" "Word of the Day is not blank"
test_section_multiline "Word" "Word of the Day" "adjective\|noun\|verb\|adverb" "Word shows part of speech"

# Test 7: Wikipedia has actual content (not N/A)
test_section_not_contains "Wikipedia Content" "📰.*N/A" "Wikipedia title is not N/A"
test_section_multiline "Wikipedia" "Wikipedia Featured" "https://en.wikipedia.org" "Wikipedia shows URL"

# Test 8: APOD has content
test_section_multiline "APOD" "Astronomy Picture" "🌌" "APOD shows title"

# Test 9: APOD URL doesn't show literal "null"
test_section_not_contains "APOD URL" "🔗 null$" "APOD URL is not literal null"

# Test 10: Calendar section exists
test_section "Calendar" "Today's Calendar" "Calendar section shows"

# Test 11: Email section exists and is properly formatted
test_section "Email" "Recent Unread Emails\|📧" "Email section shows"

# Test 12: Learning tip generates
test_section_multiline "Learning" "Personalized Learning Tip" "Source:" "Learning tip shows with source"

echo ""
echo "${CYAN}--- Regression Tests ---${NC}"
echo ""

# Regression: Check for common failure patterns

# R1: No "null" literals in output (except as valid content)
if grep -E "🔗 null$|: null$|  null$" "$OUTPUT_FILE" | grep -v "may be null"; then
  echo "${RED}✗${NC} Regression: Found literal 'null' values in output"
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
else
  echo "${GREEN}✓${NC} Regression: No literal 'null' values displayed"
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# R2: No empty sections with just N/A
NA_COUNT=$(grep -c "N/A$" "$OUTPUT_FILE" 2>/dev/null || true)
NA_COUNT=${NA_COUNT:-0}
if [[ $NA_COUNT -gt 3 ]]; then
  echo "${RED}✗${NC} Regression: Too many N/A values ($NA_COUNT found)"
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
else
  echo "${GREEN}✓${NC} Regression: Acceptable N/A count ($NA_COUNT)"
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# R3: No jq parse errors
if grep -q "parse error\|Invalid string" "$OUTPUT_FILE"; then
  echo "${RED}✗${NC} Regression: Found jq parse errors in output"
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
else
  echo "${GREEN}✓${NC} Regression: No jq parse errors"
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# R4: No curl/API errors visible
if grep -qi "curl.*error\|API.*error\|connection refused" "$OUTPUT_FILE"; then
  echo "${RED}✗${NC} Regression: Found API/curl errors in output"
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
else
  echo "${GREEN}✓${NC} Regression: No API/curl errors visible"
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# Cleanup
rm -f "$OUTPUT_FILE"

# Summary
echo ""
echo "${CYAN}========================================${NC}"
echo "${CYAN}  Test Summary${NC}"
echo "${CYAN}========================================${NC}"
echo ""
echo "Total tests: $TESTS_RUN"
echo "${GREEN}Passed: $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
  echo "${RED}Failed: $TESTS_FAILED${NC}"
fi
echo ""

# Exit with failure if any tests failed
if [[ $TESTS_FAILED -gt 0 ]]; then
  echo "${RED}E2E tests failed!${NC}"
  exit 1
else
  echo "${GREEN}All E2E tests passed!${NC}"
  exit 0
fi
