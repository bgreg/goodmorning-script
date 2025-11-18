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

3. Follow the interactive prompts to configure your development environment.

## Running Tests

The project includes a comprehensive test suite covering syntax validation, security checks, resource handling, integration tests, functional tests, error handling, and regression tests.

### Run All Tests

```bash
./tests/run-all-tests.sh
```

### Run Individual Test Phases

```bash
./tests/test-phase1-syntax.sh          # Syntax validation
./tests/test-phase2-security.sh        # Security checks
./tests/test-phase3-resources.sh       # Resource management
./tests/test-phase4-integration.sh     # Integration tests
./tests/test-phase5-functional.sh      # Functional tests
./tests/test-phase6-errorhandling.sh   # Error handling
./tests/test-phase7-regression.sh      # Regression tests
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

1. **Test File Naming:** `test-phase{N}-{category}.sh`
2. **Test Setup Files:** `test-setup-phase{N}-{category}.sh`
3. **Test Helpers:** Use shared helpers from `tests/test-helpers.sh`
4. **Assertions:** Clearly document expected vs actual behavior
5. **Cleanup:** Always clean up temporary files and processes

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
   ./tests/run-all-tests.sh
   ```

5. **Submit Pull Request:**
   - Provide clear description of changes
   - Reference any related issues
   - Include test results

6. **Code Review:**
   - Address reviewer feedback
   - Keep commits focused and atomic
   - Squash commits if requested

## Project Structure

```text
goodmorning-script/
├── goodmorning.sh           # Main script
├── setup.sh                 # Setup and configuration script
├── LICENSE                  # MIT License
├── README.md                # Project documentation
├── CONTRIBUTING.md          # This file
├── postgresql-docs.txt      # Sample documentation links
├── tests/                   # Test suite
│   ├── run-all-tests.sh
│   ├── test-helpers.sh
│   ├── test-phase*.sh       # Test phases
│   └── test-setup-phase*.sh # Setup tests
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
- Examine test files for code examples
- Open an issue for questions or clarifications

## License

By contributing to Good Morning Script, you agree that your contributions will be licensed under the MIT License.
