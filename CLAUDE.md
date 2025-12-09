# Good Morning Script

Zsh-based daily briefing automation for macOS
Personal productivity tool with TDD workflow.

## Quick Commands

```bash
./goodmorning.sh           # Run daily briefing
./tests/run_tests.sh       # Run all tests
```

## Critical Workflow

**TDD is mandatory** - Red-Green-Refactor paradigm required for ALL changes:

1. Edit `real_api_spec.sh` to describe bug/feature (failing e2e test)
2. Create failing unit specs for each function needed
3. Implement code until unit tests pass
4. Verify e2e spec passes
5. Manual test run required before completion

## Key Context

- Zsh scripting throughout
- macOS APIs (osascript, icalBuddy)
- Installed locally with symlinks in `$HOME/.config`
- Development in `$HOME/workspace/goodmorning-script`

## Entry Points

- Main script: `goodmorning.sh`
- Tests: `tests/`
- Lib functions: `lib/`

## Related Projects

- **dotfiles** (../dotfiles) - Provides environment foundation

## Branch Artifacts

All branch-specific work artifacts should be organized in `.claude/branches/<branch-name>/`:
- Implementation plans and task breakdowns
- Temporary debugging scripts
- Analysis notes and research
- Any branch-specific documentation

This keeps the main `.claude/` directory clean and makes branch cleanup easier.

## Git Workflow

**Commit Attribution**: Never include Claude Code attribution or Co-Authored-By tags in commits unless explicitly requested. Commits should appear as authored by the developer using the tool.

Follow workspace git standards if present, otherwise follow standard git practices.
