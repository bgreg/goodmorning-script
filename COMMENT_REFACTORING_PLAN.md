# Comment Refactoring Plan

## Executive Summary

This plan reviews all inline comments within functions across the goodmorning-script codebase and categorizes them based on whether they should be:
1. **Kept** - Valuable documentation that aids understanding
2. **Removed** - Redundant with self-explanatory code
3. **Refactored** - Better expressed through function names or extracted functions

## Analysis Categories

### ✅ KEEP - Good Documentation Comments

These comments provide valuable context that isn't obvious from code alone:

#### Function-Level Documentation Blocks
**Location**: Multiple files (utilities.sh, view_helpers.sh, validation_helpers.sh, preflight/network.sh)
**Finding**: All function-level documentation blocks with usage examples are excellent
**Recommendation**: **KEEP ALL** - These follow best practices with:
- Clear purpose statements
- Parameter documentation
- Usage examples
- Return value documentation

**Example** (lib/utilities.sh:9-11):
```zsh
# Helper function to source library files with optional required validation
# Usage: _source_lib "lib/app/colors.sh" [required]
# Returns: 0 if file sourced successfully, 1 if file missing
```

---

### 🔄 REFACTOR - Extract to Private Functions

These comments indicate complex logic that should be extracted:

#### 1. iTerm2 Badge Status Creation
**File**: lib/app/core.sh:78-105
**Current**: Large function with repeated timeout pattern comments
```zsh
# Count unread mail (silent, non-blocking with timeout)
# Count incomplete reminders (silent, non-blocking with timeout)
# Count today's calendar events (silent, non-blocking with timeout)
```

**Issue**: Repetitive pattern, each fetch is similar logic
**Recommendation**: Extract to private helper function
```zsh
_fetch_count_with_timeout() {
  local script_path="$1"
  local timeout_seconds="${2:-2}"
  local count=0

  if timeout $timeout_seconds osascript "$script_path" &>/dev/null; then
    count=$(timeout $timeout_seconds osascript "$script_path" 2>/dev/null || echo "0")
    [[ "$count" =~ ^[0-9]+$ ]] || count=0
  fi

  echo "$count"
}
```

Then simplify the main function:
```zsh
iterm_create_status_badge() {
  local mail_count=$(_fetch_count_with_timeout "$SCRIPT_DIR/lib/app/apple_script/count_mail.scpt")
  local reminder_count=$(_fetch_count_with_timeout "$SCRIPT_DIR/lib/app/apple_script/count_reminders.scpt")
  local calendar_count=$(_fetch_count_with_timeout "$SCRIPT_DIR/lib/app/apple_script/count_calendar.scpt")

  local badge_text="📧 $mail_count  ✅ $reminder_count  📅 $calendar_count"
  echo "$badge_text"
}
```

**Benefits**:
- Eliminates 3 identical comments
- DRY principle
- Easier to test
- Clearer intent

---

#### 2. Cursor Management in Spinner Functions
**File**: lib/app/core.sh:305-314
**Current**:
```zsh
# Hide terminal cursor
_hide_cursor() { ... }

# Show terminal cursor
_show_cursor() { ... }
```

**Issue**: Comments just restate function names
**Recommendation**: **REMOVE COMMENTS** - Function names are perfectly clear

---

#### 3. Timeout Checking Logic
**File**: lib/app/core.sh:323-340
**Current**: Multiple small helper functions with comments
```zsh
# Check if process has exceeded timeout
# Returns: 0 if timeout exceeded, 1 if still within timeout
_has_timed_out() { ... }

# Handle timeout: cleanup and return error
_handle_timeout() { ... }
```

**Recommendation**: **KEEP** - These comments document return value semantics which are counterintuitive (0 = exceeded is opposite of typical success/fail)

---

#### 4. Word of the Day Selection Logic
**File**: lib/app/sections/word_of_day.sh:13-40
**Current**: Large comment block explaining selection criteria
```zsh
# Use system dictionary, filtering for interesting words
# Criteria: 7-15 characters, lowercase only (no proper nouns), exclude common words
...
# Get day of year for deterministic daily selection
...
# Filter dictionary for interesting words and select based on day of year
# - Length between 7-15 characters (interesting but not too obscure)
# - Lowercase only (excludes proper nouns)
# - Alphabetic characters only
```

**Issue**: Multiple comments explaining the same concept
**Recommendation**: Consolidate to a single function-level comment and rename function:
```zsh
###############################################################################
# get_deterministic_daily_word - Select interesting word based on day of year
#
# Uses /usr/share/dict/words with filtering criteria:
# - Length: 7-15 characters (interesting but not obscure)
# - Lowercase only (excludes proper nouns)
# - Day-based selection for consistency throughout the day
#
# Returns: A single word, or "serendipity" if dictionary unavailable
###############################################################################
get_deterministic_daily_word() {
  local dict_file="/usr/share/dict/words"

  if [[ ! -f "$dict_file" ]]; then
    echo "ephemeral"
    return
  fi

  local day_of_year=$(date +%j | sed 's/^0*//')

  local word=$(grep -E '^[a-z]{7,15}$' "$dict_file" | \
    sed -n "${day_of_year}~50p" | \
    head -1)

  if [[ -z "$word" ]]; then
    word="serendipity"
  fi

  echo "$word"
}
```

**Benefits**:
- All criteria documented once at top
- Better function name indicates "deterministic" behavior
- Remove redundant inline comments
- Clearer fallback values

---

#### 5. Sitemap URL Extraction
**File**: lib/app/sitemap.sh:18-22, 36-49, 58-62
**Current**: Inline comments explaining sed/grep pipelines
```zsh
# Extract URLs from <loc> tags
urls=(${(f)"$(echo "$sitemap_content" | \
        grep -o '<loc>[^<]*</loc>' | \
        sed 's|<loc>\(.*\)</loc>|\1|' | \
        grep -v '\.\(png\|jpg\|jpeg\|gif\|svg\|css\|js\|xml\|pdf\)$')"})
```

**Issue**: Complex pipeline needs explanation
**Recommendation**: Extract to well-named private function
```zsh
_extract_loc_urls_from_xml() {
  local xml_content="$1"
  echo "$xml_content" | \
    grep -o '<loc>[^<]*</loc>' | \
    sed 's|<loc>\(.*\)</loc>|\1|'
}

_filter_non_content_urls() {
  grep -v '\.\(png\|jpg\|jpeg\|gif\|svg\|css\|js\|xml\|pdf\)$'
}

_filter_documentation_urls() {
  grep -E '(doc|guide|tutorial|reference|api|manual|learn)'
}
```

Then refactor functions to use these:
```zsh
fetch_sitemap_urls() {
  local sitemap_url="$1"
  local sitemap_content=$(curl -s -L --compressed --max-time 10 "$sitemap_url" 2>/dev/null)

  if [ -n "$sitemap_content" ]; then
    _extract_loc_urls_from_xml "$sitemap_content" | _filter_non_content_urls
  fi
}

fetch_doc_sitemap_urls() {
  local sitemap_url="$1"
  local sitemap_content=$(curl -s -L --compressed --max-time 10 "$sitemap_url" 2>/dev/null)

  if [ -n "$sitemap_content" ]; then
    local doc_urls=$(_extract_loc_urls_from_xml "$sitemap_content" | _filter_documentation_urls | _filter_non_content_urls)

    if [ -z "$doc_urls" ]; then
      # Fallback to all content URLs if no documentation URLs found
      _extract_loc_urls_from_xml "$sitemap_content" | _filter_non_content_urls
    else
      echo "$doc_urls"
    fi
  fi
}
```

**Benefits**:
- Self-documenting function names
- Reusable components
- Eliminates 3 similar comment blocks
- Easier to test individual filters
- Comment about fallback logic becomes clear from code structure

---

### ❌ REMOVE - Redundant Comments

These comments restate what the code clearly shows:

#### 1. State Management Comments
**File**: lib/app/core.sh:251, 283
```zsh
# Hide cursor during spinner
printf "\e[?25l"
...
# Restore cursor
printf "\e[?25h"
```

**Issue**: Comments just describe the immediate next line
**Recommendation**: **REMOVE** - The code with ANSI escape sequences is standard terminal manipulation. If needed, the function name should indicate cursor management.

**Alternative**: Extract to `_with_hidden_cursor()` wrapper if this pattern repeats

---

#### 2. Simple Step Comments
**File**: lib/app/core.sh:428
```zsh
# Read and output results
output=$(cat <&3)
exec 3<&-
```

**Issue**: Comment adds no value beyond variable name
**Recommendation**: **REMOVE**

---

#### 3. Flow Comments
**File**: lib/app/core.sh:418
```zsh
# Run spinner (animated or silent)
if [[ "$use_animation" == "true" ]]; then
  _run_animated_spinner "$message" "$pid" "$tty_out" "$max_iterations" || return 1
else
  _wait_silently "$pid" "$max_iterations" || return 1
fi
```

**Issue**: The if/else structure with function names makes this obvious
**Recommendation**: **REMOVE**

---

#### 4. Special Case Comments
**File**: lib/app/sanity_maintenance.sh:60
```zsh
# special case handling for xkcd
if [[ "$url" == "xkcd:random" ]]; then
```

**Issue**: The conditional itself shows it's a special case
**Recommendation**: Extract to private function `_handle_xkcd_random_url()` and remove comment

---

### 📝 CLARIFY - Comments Worth Improving

These comments are valuable but could be enhanced:

#### 1. Trap Explanation
**File**: lib/app/core.sh:27
```zsh
# when the script exits or is interrupted, clean up background processes
trap cleanup_background_processes EXIT INT TERM
```

**Current**: Lowercase, informal style
**Recommendation**: Update to match documentation style:
```zsh
# Register cleanup handler for script termination (EXIT, INT, TERM signals)
trap cleanup_background_processes EXIT INT TERM
```

---

#### 2. JSON Parsing Sanitization
**File**: lib/app/display.sh:62
```zsh
# Remove control characters that break jq parsing
local cleaned_data=$(printf '%s' "$history_data" | LC_ALL=C tr -d '\000-\037')
```

**Current**: Good comment, explains WHY
**Recommendation**: **KEEP** - This is a defensive programming technique that isn't obvious

---

#### 3. Badge Theme Comment
**File**: lib/app/core.sh:102
```zsh
# Create badge with counts (using blue/green theme)
local badge_text="📧 $mail_count  ✅ $reminder_count  📅 $calendar_count"
```

**Issue**: Theme colors aren't actually in the code (they're in the emojis?)
**Recommendation**: Either remove the theme part or clarify what it means, or remove entirely since the emoji usage is self-evident

---

#### 4. Carriage Return Technique
**File**: lib/app/core.sh:273
```zsh
# Use carriage return to overwrite - works with any character width
printf "\r  %s... %s  " "$message" "${spin_chars[$((spin_index + 1))]}"
```

**Current**: Explains technique
**Recommendation**: **KEEP** - Explains WHY this approach over backspaces (character width independence)

---

#### 5. Process Substitution Comment
**File**: lib/app/core.sh:414
```zsh
# Run command and capture output using process substitution
exec 3< <("${command[@]}" 2>/dev/null)
local pid=$!
```

**Current**: Explains the technique
**Recommendation**: **KEEP** - Process substitution with file descriptor capture is non-obvious

---

## Summary Statistics

| Category | Count | Action |
|----------|-------|--------|
| Function-level docs | ~30+ | ✅ KEEP ALL |
| Extract to functions | 5 | 🔄 REFACTOR |
| Remove redundant | 7 | ❌ REMOVE |
| Clarify/improve | 4 | 📝 ENHANCE |

## Implementation Priority

### Phase 1: Quick Wins (Remove Redundant)
- Remove simple step comments
- Remove cursor management comments
- Remove flow comments
- **Effort**: Low (15 minutes)
- **Impact**: Immediate code clarity

### Phase 2: Extract Functions (High Value)
1. `_fetch_count_with_timeout()` - iTerm badge helper
2. Sitemap URL extraction functions
3. `_handle_xkcd_random_url()` - Special case handler
4. Word selection refactor with consolidated docs
- **Effort**: Medium (2-3 hours)
- **Impact**: High - eliminates repeated patterns, improves testability

### Phase 3: Documentation Enhancement
- Improve trap comment
- Review theme comment
- Verify technical explanation comments
- **Effort**: Low (30 minutes)
- **Impact**: Medium - professional consistency

## Testing Requirements

After refactoring:
1. Run full test suite: `./tests/run_tests.sh`
2. Manual smoke test: `./goodmorning.sh`
3. Verify extracted functions have unit tests
4. Check that behavior is identical before/after

## Files Requiring Changes

### High Priority
- `lib/app/core.sh` - Most comments, biggest impact
- `lib/app/sitemap.sh` - Extract URL filtering functions
- `lib/app/sections/word_of_day.sh` - Consolidate selection logic

### Medium Priority
- `lib/app/sanity_maintenance.sh` - Extract xkcd handler
- `lib/app/display.sh` - Minor cleanup

### Low Priority (Keep as-is)
- `lib/utilities.sh` - Already excellent
- `lib/setup/validation_helpers.sh` - Already excellent
- `lib/app/preflight/network.sh` - Already excellent
- `lib/app/view_helpers.sh` - Already excellent

## Principles Applied

1. **Self-Documenting Code First**: Function names should explain intent
2. **Comments for "Why", Not "What"**: Keep comments that explain reasoning
3. **DRY with Functions**: Repeated patterns → extracted functions
4. **Technical Context**: Keep comments explaining non-obvious techniques
5. **API Documentation**: Keep all function-level documentation blocks

## Future Considerations

- Consider adding shellcheck directives where appropriate
- Consider documenting public vs private function conventions (leading underscore)
- Consider creating a CONTRIBUTING.md with comment style guide
