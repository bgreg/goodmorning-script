# Contributing to Good Morning Script

Thank you for your interest in contributing to the Good Morning Script! This document provides guidelines and instructions for contributing to the project.

## Development Setup

### Prerequisites

**Required:**

- macOS (Darwin-based system)
- zsh shell
- curl
- git

**Optional (for full functionality):**

- Homebrew (for package updates feature)
- jq (for Wikipedia history feature)
- figlet (for custom ASCII banners)
- icalBuddy (for calendar/reminders integration)
- Claude Code (for AI-powered learning tips)
- ShellSpec (for running tests)

### Installation for Development

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd goodmorning-script
   ```

2. Run the setup script:

   ```bash
   ./setup.sh
   ```

3. Install ShellSpec for testing:

   ```bash
   brew install shellspec
   ```

4. Follow the interactive prompts to configure your development environment.

## Running Tests

The project uses [ShellSpec](https://shellspec.info/) for testing with specs organized by component.

### Run All Tests

```bash
shellspec
```

### Run Specific Specs

```bash
shellspec spec/goodmorning/          # Goodmorning script specs
shellspec spec/setup/                # Setup script specs
shellspec spec/lib/                  # Library specs
```

### Run E2E Tests (Real APIs)

E2E tests hit real APIs and require internet connectivity. They're skipped by default:

```bash
SHELLSPEC_REAL=1 shellspec
```

### Test Output Formats

```bash
shellspec --format documentation     # Verbose output (default)
shellspec --format progress          # Compact progress dots
shellspec --format tap               # TAP format for CI
```

### Test Requirements

All contributions must:

- Pass all existing tests
- Include new tests for new functionality
- Maintain or improve code coverage

## Code Style Guidelines

### Shell Scripting Standards

1. **Shebang:** Always use `#!/usr/bin/env zsh`

2. **Local Variables:** Use `local` keyword for function-scoped variables

   ```bash
   function_name() {
     local var_name="value"
   }
   ```

3. **Variable Naming:
   - Lowercase for local/function variables: `local user_name="value"`
   - UPPERCASE for environment variables and constants: `GOODMORNING_CONFIG_DIR`

4. **Error Handling:**
   - Use explicit error checks rather than `set -euo pipefail`
   - Gracefully degrade when optional features are unavailable
   - Return meaningful exit codes

5. **Comments:**
   - Prioritize self-documenting code over comments
   - Only add comments for:
     - Security warnings on dangerous operations
     - Non-obvious algorithmic explanations
     - Compatibility or version constraints
     - Legal requirements (license headers, copyright)

6. **Quoting:** Always quote variable expansions: `"${var}"`

7. **Security:**
   - Validate and sanitize all user inputs
   - Check file permissions before sourcing scripts
   - Use safe temporary file handling

### Testing Standards

1. **Spec File Naming:** `{component}_spec.sh` (e.g., `configuration_spec.sh`)
2. **Spec Organization:** Group by component in `spec/{component}/`
3. **Spec Helper:** Use `spec/spec_helper.sh` for shared setup
4. **Assertions:** Use ShellSpec matchers for clear expectations
5. **Cleanup:** Use `AfterAll` or `AfterEach` for cleanup
6. **Tagging:** Use tags for special test categories (e.g., `:real` for E2E)

Example spec structure:

```bash
Describe 'Feature name'
  It 'does something expected'
    When call some_function
    The status should be success
    The output should include "expected"
  End
End
```

## Pull Request Process

1. **Fork and Branch:**
   - Fork the repository
   - Create a feature branch: `git checkout -b feature/your-feature-name`

2. **Make Changes:**
   - Follow the code style guidelines
   - Write or update tests as needed
   - Ensure all tests pass

3. **Commit:**
   - Use imperative mood in commit messages: "Add feature" not "Added feature"
   - Keep the summary line under 50 characters
   - Add detailed explanation if needed

4. **Test:**

   ```bash
   shellspec
   ```

5. **Submit Pull Request:**
   - Provide clear description of changes
   - Reference any related issues
   - CI will run tests automatically

6. **Code Review:**
   - Address reviewer feedback
   - Keep commits focused and atomic
   - Squash commits if requested

## Project Structure

```text
goodmorning-script/
├── goodmorning.sh           # Main script
├── setup.sh                 # Setup and configuration script
├── lib/                     # Modular function library
├── LICENSE                  # MIT License
├── README.md                # Project documentation
├── CONTRIBUTING.md          # This file
├── postgresql-docs.txt      # Sample documentation links
├── .shellspec               # ShellSpec configuration
├── spec/                    # Test suite
│   ├── spec_helper.sh       # Shared test setup
│   ├── support/             # Test support files
│   ├── goodmorning/         # Main script specs
│   ├── setup/               # Setup script specs
│   ├── lib/                 # Library specs
│   └── e2e/                 # End-to-end specs
└── .github/
    └── workflows/
        └── test.yml         # CI configuration
```

## Feature Development Guidelines

### Adding New Features

1. **Discuss First:** Open an issue to discuss major features before implementation
2. **Graceful Degradation:** New features should degrade gracefully if dependencies are missing
3. **Configuration:** Add environment variables for feature configuration
4. **Documentation:** Update README.md with new features and configuration options
5. **Tests:** Add comprehensive tests for new functionality

### Environment Variables

New environment variables should:

- Use `GOODMORNING_` prefix
- Provide sensible defaults
- Be documented in README.md and setup.sh
- Be validated when critical for security

### Error Messages

- Use color-coded output (COL_RED, COL_YELLOW, COL_GREEN)
- Provide actionable guidance for users
- Respect `GOODMORNING_SHOW_SETUP_MESSAGES` setting
- Write errors to stderr: `>&2`

## Security Considerations

- Never execute unsanitized user input
- Validate file paths before operations
- Check file permissions before sourcing
- Use secure temporary file creation
- Sanitize data before passing to external commands

## Getting Help

- Check existing issues and pull requests
- Review the README.md for usage examples
- Examine spec files for code examples
- Open an issue for questions or clarifications

## License

By contributing to Good Morning Script, you agree that your contributions will be licensed under the MIT License.
