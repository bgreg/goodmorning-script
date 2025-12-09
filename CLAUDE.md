# Good Morning Script

Personal daily briefing automation tool for macOS.

## Project Overview

A zsh-based terminal application that provides a comprehensive daily briefing with:
- Weather, calendar events, and reminders
- GitHub notifications and PR reviews
- Learning resources and tech version updates
- Fun diversions (word of the day, cat pictures, etc.)
- System maintenance and backups

This is a personal project focused on productivity and automation.

## Quick Commands

```bash
./goodmorning.sh           # Run daily briefing
shellspec                  # Run all tests
shellspec spec/lib/        # Run specific test suite
```

## Development Workflow

**TDD is mandatory** - Red-Green-Refactor paradigm required for ALL changes:

1. Write/edit specs to describe bug/feature (failing test)
2. Create failing unit specs for each function needed
3. Implement code until tests pass
4. Verify all specs pass
5. Manual test run required before completion

## Technical Details

- **Language**: Zsh shell scripting
- **Platform**: macOS (uses osascript, icalBuddy, iTerm2 APIs)
- **Test Framework**: ShellSpec
- **Installation**: Local with symlinks in `$HOME/.config`
- **Development**: `$HOME/workspace/goodmorning-script`

## Architecture

```
goodmorning.sh              # Main entry point
├── lib/
│   ├── utilities.sh        # Shared utility functions
│   ├── app/
│   │   ├── core.sh         # Core utilities, spinners, iTerm2 integration
│   │   ├── display.sh      # Display functions for sections
│   │   ├── colors.sh       # Terminal color functions
│   │   ├── preflight/      # Startup checks (OS, shell, network, tools)
│   │   ├── sections/       # Individual briefing sections
│   │   └── ...
│   └── setup/              # Setup and validation helpers
├── spec/                   # ShellSpec test suites
├── data/                   # Configuration data (JSON)
└── examples/               # Templates for custom sections
```

## Key Patterns

1. **Utilities First**: Common patterns extracted to `lib/utilities.sh`
   - HTTP fetching, random selection, validation, string transforms
2. **Self-Documenting**: Function names explain intent; comments explain "why"
3. **DRY Functions**: Extract repeated patterns into reusable helpers
4. **Minimal Comments**: Prefer clear code over explanatory comments

## Testing

All changes must include tests:
- Unit tests: `spec/lib/` for library functions
- Integration tests: `spec/goodmorning/` for main script
- E2E tests: `spec/e2e/` for real API interactions

Run tests:
```bash
shellspec                          # All tests
shellspec spec/lib/core_spec.sh   # Specific file
shellspec --tag focus              # Tagged tests
```

## Related Projects

- **dotfiles** (../dotfiles) - Provides environment foundation and shell configuration

## Git Workflow

Follow standard git practices:
- Descriptive commit messages
- One logical change per commit
- Test before committing
- Keep commits focused and atomic
