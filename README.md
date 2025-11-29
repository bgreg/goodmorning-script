# Good Morning Script

> A customizable daily briefing script for your terminal that displays weather, calendar events, reminders, and personalized learning tips to start your day.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)
[![Shell](https://img.shields.io/badge/shell-zsh-blue.svg)](https://www.zsh.org/)

## Requirements

**⚠️ macOS Only** - This script uses macOS-specific features:
- **macOS 10.15+** (Catalina or later)
- **zsh** (default shell on macOS since Catalina - already installed)
- **Internet connection** (optional - gracefully degrades in offline mode)

## Features

- Customizable ASCII art banner (auto-generated with figlet)
- Current weather forecast
- Historical events on this day
- **Latest Tech Versions** - displays current versions of popular languages & frameworks (Ruby, Rails, TypeScript, Next.js, React, Rust, Go, Elixir, Phoenix, Python, Django)
- **Country of the Day** - random country facts with flag, capital, population, languages, and more (REST Countries API)
- **Word of the Day** - vocabulary expansion with definitions from Merriam-Webster
- **Wikipedia Featured Article** - today's featured article with summary and link
- **Astronomy Picture of the Day** - NASA's APOD with inline image display in iTerm2
- Today's calendar events (via icalBuddy or macOS Calendar)
- Reminders and tasks due today
- **Daily Learning** - customizable topic categories with random link suggestions
- **Sanity Maintenance** - random entertainment links (comics, games, forums)
- AI-generated personalized learning tips (requires Claude Code)
- Background system updates (Homebrew, Vim plugins, custom scripts)
- macOS notification when updates complete
- **Output History** - saves daily briefings with 7-day retention
- Optional text-to-speech greeting (disabled by default, enable with `--noisy` flag)
- **Offline mode detection** - automatically skips internet-requiring features when offline
- **Smart caching** - all API data cached for 24 hours to minimize API calls
- Modular AppleScript organization for better maintainability
- Optional completion callback for custom post-processing

## What Does It Look Like?

When you run the script, you'll see a formatted terminal output with:

```
   ____                 _   __  __                   _
  / ___| ___   ___   __| | |  \/  | ___  _ __ _ __ (_)_ __   __ _
 | |  _ / _ \ / _ \ / _` | | |\/| |/ _ \| '__| '_ \| | '_ \ / _` |
 | |_| | (_) | (_) | (_| | | |  | | (_) | |  | | | | | | | | (_| |
  \____|\___/ \___/ \__,_| |_|  |_|\___/|_|  |_| |_|_|_| |_|\__, |
                                                             |___/

========================================
  Weather
========================================
  ☀️ Current: 72°F, Partly Cloudy
  📍 San Francisco, CA

========================================
  On This Day in History
========================================
  • 1903 - Wright brothers' first flight
  • 1969 - Apollo 11 lands on the moon

========================================
  Latest Tech Versions
========================================
  Ruby            3.3.0           Rails           7.1.2
  TypeScript      5.3.3           Next.js         14.0.4
  React           18.2.0          Rust            1.75.0
  Go              1.21.5          Elixir          1.16.0
  Phoenix         1.7.10          Python          3.12.1
  Django          5.0.0

  💡 Cached for 24 hours

========================================
  Country of the Day
========================================
  🇯🇵  Japan
  Official: Japan

  🏛️  Capital: Tokyo
  🌍 Region: Asia (Eastern Asia)
  👥 Population: 125,584,838
  📏 Area: 377,930 km²
  🗣️  Languages: Japanese
  💰 Currency: Japanese yen

  💡 Daily rotation - refreshes every 24 hours

========================================
  Word of the Day
========================================
  📖 serendipity

  The faculty or phenomenon of finding valuable or agreeable
  things not sought for. Also : an instance of this.

========================================
  Wikipedia Featured Article
========================================
  📰 The Great Wave off Kanagawa

  The Great Wave off Kanagawa is a woodblock print by Japanese
  ukiyo-e artist Hokusai, created in late 1831 during the Edo
  period of Japanese history...

  🔗 https://en.wikipedia.org/wiki/The_Great_Wave_off_Kanagawa

========================================
  Astronomy Picture of the Day
========================================
  🌌 Northern Lights Over Norway

  [Image displays inline in iTerm2]

  Explanation of today's astronomical image from NASA...

  🔗 https://apod.nasa.gov/apod/...

========================================
  Today's Calendar
========================================
  9:00 AM - Team standup
  2:00 PM - Code review session

========================================
  Daily Learning
========================================
  📚 PostgreSQL: Understanding Indexes
  🔗 https://www.postgresql.org/docs/current/indexes.html

========================================
  🤪 Sanity Maintenance
========================================
  Comics:
    XKCD: Machine Learning
    https://xkcd.com/1838/

  Games:
    Wordle
    https://www.nytimes.com/games/wordle/index.html

========================================
  💡 Today's Learning Tip
========================================
  Based on your recent work with PostgreSQL migrations...
  [AI-generated personalized tip]

🔄 Background updates running... (Homebrew, Vim plugins, etc.)

Log: ~/.config/goodmorning/logs/goodmorning.log
Output saved: ~/.config/goodmorning/output_history/Tuesday/goodmorning-1.txt
```

The script adapts to your configuration and available data sources.

## Quick Start

The easiest way to get started is using the interactive setup script:

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/goodmorning-script.git
cd goodmorning-script

# Run the interactive setup script
./setup.sh

# Or use defaults and run immediately
./setup.sh --run
```

The setup script will:
- Guide you through configuration with helpful prompts
- Validate all file and directory paths
- Save your configuration to `~/.config/goodmorning/config.sh`
- Provide instructions for adding to your shell profile

## Installation

### Using the Setup Script (Recommended)

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/goodmorning-script.git
   cd goodmorning-script
   ```
2. Run the interactive setup:
   ```bash
   ./setup.sh
   ```
3. Follow the prompts to configure your preferences
4. Add to your `.zshrc`:
   ```bash
   # Source Good Morning configuration
   source ~/.config/goodmorning/config.sh

   # Optional: Create alias for quick access
   alias gm="$HOME/goodmorning-script/goodmorning.sh"
   ```

### Setup Script Options

```bash
./setup.sh              # Run interactive setup
./setup.sh --run        # Setup (if needed) then run the script
./setup.sh --reconfigure   # Force re-running setup
./setup.sh --show-config   # Display current configuration
./setup.sh --regenerate-banner   # Regenerate ASCII art banner
./setup.sh --help       # Show help message
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/goodmorning-script.git
   cd goodmorning-script
   ```
2. Make the script executable:
   ```bash
   chmod +x goodmorning.sh
   ```
3. Set environment variables and add to your shell profile (`.zshrc`, `.bashrc`, etc.):
   ```bash
   export GOODMORNING_USER_NAME="YourName"
   # Add other variables as needed (see Configuration section)
   /path/to/goodmorning.sh
   ```

### Optional Dependencies

Install these tools for full functionality:

```bash
# Calendar integration
brew install ical-buddy

# JSON parsing for Wikipedia history
brew install jq

# ASCII art banner generation
brew install figlet

# AI-powered learning tips
# Install Claude Code from https://claude.ai/code
```

## Usage

### Command Line Options

```bash
./goodmorning.sh          # Run with default settings
./goodmorning.sh --noisy  # Enable text-to-speech greeting
./goodmorning.sh --help   # Show help message
```

**Text-to-Speech:**
By default, the spoken "Good morning" greeting is disabled. Enable it with:
- Runtime flag: `./goodmorning.sh --noisy`
- Environment variable: `export GOODMORNING_ENABLE_TTS=true`
- Setup script: Answer "yes" when prompted during `./setup.sh`

**Offline Mode:**
The script automatically detects internet connectivity and skips features that require internet access (weather, history API, learning tips). You can force offline mode:
```bash
export GOODMORNING_FORCE_OFFLINE=1
./goodmorning.sh
```

## Configuration

Configuration is managed through environment variables. The setup script handles this automatically, or you can configure manually.

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `GOODMORNING_CONFIG_DIR` | Directory for configuration and data files | `$HOME/.config/goodmorning` | No |
| `GOODMORNING_USER_NAME` | Name used in greeting | `$USER` | No |
| `GOODMORNING_ENABLE_TTS` | Enable text-to-speech greeting | `false` | No |
| `GOODMORNING_BANNER_FILE` | Path to ASCII art banner file | `$GOODMORNING_CONFIG_DIR/banner.txt` | No |
| `GOODMORNING_LEARNING_SOURCES_FILE` | Path to daily learning sources file | `$GOODMORNING_CONFIG_DIR/learning-sources.json` | No |
| `GOODMORNING_LOGS_DIR` | Directory for log files | `$GOODMORNING_CONFIG_DIR/logs` | No |
| `GOODMORNING_OUTPUT_HISTORY_DIR` | Directory for output history | `$GOODMORNING_CONFIG_DIR/output_history` | No |
| `GOODMORNING_SHOW_WEATHER` | Show weather section | `true` | No |
| `GOODMORNING_SHOW_HISTORY` | Show history section | `true` | No |
| `GOODMORNING_SHOW_LEARNING` | Show daily learning section | `true` | No |
| `GOODMORNING_SHOW_SANITY` | Show sanity maintenance section | `true` | No |
| `GOODMORNING_SHOW_TIPS` | Show AI learning tips | `true` | No |
| `GOODMORNING_BACKUP_SCRIPT` | Path to backup script to run | (none) | No |
| `GOODMORNING_VIM_PLUGINS_DIR` | Vim plugins directory to update | `$HOME/.vim/pack/vendor/start` | No |
| `GOODMORNING_PROJECT_DIRS` | Colon-separated directories to scan for git commits | `$HOME` | No |
| `GOODMORNING_COMPLETION_CALLBACK` | Path to script to run after all sections complete | (none) | No |
| `GOODMORNING_SHOW_SETUP_MESSAGES` | Show installation/setup messages for missing features | `true` | No |
| `GOODMORNING_FORCE_OFFLINE` | Force offline mode (skip internet-requiring features) | (unset) | No |
| `GOODMORNING_NASA_API_KEY` | NASA API key for APOD (uses DEMO_KEY if not set) | `DEMO_KEY` | No |

### Example Configuration

#### Using Setup Script (Recommended)

The setup script creates `~/.config/goodmorning/config.sh` with your configuration. Add to your `.zshrc` or `.bashrc`:

```bash
# Source Good Morning configuration
source ~/.config/goodmorning/config.sh

# Optional: Create alias for quick access
alias gm="$HOME/goodmorning-script/goodmorning.sh"
```

#### Manual Configuration

Add to your `.zshrc` or `.bashrc`:

```bash
# Good Morning Script Configuration
export GOODMORNING_USER_NAME="Alice"
export GOODMORNING_BACKUP_SCRIPT="$HOME/.local/bin/backup_dev.sh"
export GOODMORNING_VIM_PLUGINS_DIR="$HOME/.vim/pack/vendor/start"
export GOODMORNING_PROJECT_DIRS="$HOME/Projects:$HOME/workspace:$HOME/Documents"
export GOODMORNING_COMPLETION_CALLBACK="$HOME/.config/goodmorning/completion.sh"
export GOODMORNING_SHOW_SETUP_MESSAGES="false"  # Hide setup messages for intentionally skipped features

# Run good morning script
$HOME/goodmorning-script/goodmorning.sh
```

### Managing Configuration

View your current configuration:
```bash
./setup.sh --show-config
```

Update configuration:
```bash
./setup.sh --reconfigure
```

The setup script validates all paths and checks that:
- Script files exist and are executable
- Directories exist and are accessible
- Relative paths are converted to absolute paths

### Hiding Setup Messages

By default, the script shows helpful messages when optional features aren't configured (e.g., "Install icalBuddy for calendar integration"). If you've intentionally chosen not to use certain features, you can hide these messages:

```bash
export GOODMORNING_SHOW_SETUP_MESSAGES="false"
```

This will:
- Hide "install" messages for missing dependencies (jq, icalBuddy, Claude Code)
- Hide "skipping" messages for unconfigured scripts (backup)
- Hide "not found" messages for optional features (Mail.app, PostgreSQL docs)
- Still show actual errors (e.g., "script not found" when you've configured a path that doesn't exist)

## Customization Files

Data files are stored in `~/.config/goodmorning/` (or the directory specified by `GOODMORNING_CONFIG_DIR`).

### ASCII Art Banner (banner.txt)

The script displays an ASCII art banner from `~/.config/goodmorning/banner.txt`.

**Automatic Generation:**
During setup, you can generate a custom banner with your name using figlet:
```bash
./setup.sh              # Choose "yes" when prompted about banner
./setup.sh --regenerate-banner   # Regenerate banner anytime
```

**Manual Customization:**
Edit the banner file directly with any ASCII art you prefer:
```bash
# Edit the file
vim ~/.config/goodmorning/banner.txt

# Or generate with figlet
figlet "Your Name" > ~/.config/goodmorning/banner.txt

# Try different fonts
figlet -f banner "Your Name" > ~/.config/goodmorning/banner.txt
figlet -f big "Your Name" > ~/.config/goodmorning/banner.txt
```

**Custom Location:**
Override the default location with an environment variable:
```bash
export GOODMORNING_BANNER_FILE="/path/to/custom/banner.txt"
```

**Fallback:**
If the banner file doesn't exist, the script displays a simple text banner with your username.

### Daily Learning Sources (learning-sources.json)

The script randomly selects learning resources from `~/.config/goodmorning/learning-sources.json`. Supports both static URLs and dynamic sitemap fetching.

**JSON Format:**
```json
{
  "sitemaps": [
    {"title": "PostgreSQL Docs", "sitemap": "https://www.postgresql.org/docs/sitemap.xml"},
    {"title": "Ruby on Rails", "sitemap": "https://guides.rubyonrails.org/sitemap.xml.gz"}
  ],
  "static": [
    {"title": "AWS Lambda Guide", "url": "https://docs.aws.amazon.com/lambda/latest/dg/"},
    {"title": "GitHub Actions Docs", "url": "https://docs.github.com/en/actions"}
  ]
}
```

**How it Works:**
- Displays one random sitemap-based resource (fetched dynamically)
- Displays one random static resource
- Automatically extracts page titles from URLs
- Filters out images, CSS, and non-documentation files

The default file comes pre-populated with resources for PostgreSQL, Rails, ESLint, Zsh, AWS, and more.

### Sanity Maintenance Sources (sanity-maintenance-sources.json)

Entertainment and humor links for mental health breaks. Organized by categories.

**JSON Format:**
```json
{
  "sitemaps": [],
  "categories": {
    "comics": [
      {"title": "XKCD", "url": "xkcd:random"},
      {"title": "Random CommitStrip", "url": "https://www.commitstrip.com/?random=1"}
    ],
    "games": [
      {"title": "Wordle", "url": "https://www.nytimes.com/games/wordle/index.html"}
    ],
    "satire": [
      {"title": "The Onion", "url": "https://theonion.com"}
    ]
  }
}
```

**Special URL Types:**
- `xkcd:random` - Fetches a random XKCD comic via their API

### Output History

Daily briefings are saved to `~/.config/goodmorning/output_history/` with automatic 7-day retention.

**Structure:**
```
output_history/
  Monday/
    goodmorning-1.txt
    goodmorning-2.txt
  Tuesday/
    goodmorning-1.txt
  ...
```

Files are numbered per day and automatically cleaned after 7 days.

## Completion Callback

The script supports an optional completion callback that runs after all sections have been displayed. This allows you to add custom post-processing, logging, or additional output.

### Quick Start

1. Create a shell script:
   ```bash
   cat > ~/.config/goodmorning/completion.sh <<'EOF'
   #!/bin/bash
   # This runs after the goodmorning script completes
   # You have access to all color variables from goodmorning.sh

   echo -e "${COL_CYAN}========================================${COL_RESET}"
   echo -e "${COL_CYAN}  Custom Completion Actions${COL_RESET}"
   echo -e "${COL_CYAN}========================================${COL_RESET}"
   echo "Script completed at $(date)"
   EOF
   chmod +x ~/.config/goodmorning/completion.sh
   ```

2. Set the environment variable:
   ```bash
   export GOODMORNING_COMPLETION_CALLBACK="$HOME/.config/goodmorning/completion.sh"
   ```

### Available Color Variables

Your completion callback has access to these color variables:

- `$COL_RED` - For urgent/important items
- `$COL_GREEN` - For completed items
- `$COL_YELLOW` - For warnings/pending items
- `$COL_BLUE` - For informational items
- `$COL_MAGENTA` - For special highlights
- `$COL_CYAN` - For headers and links
- `$COL_RESET` - To reset colors

### Example Uses

- Log completion time to a file
- Display custom project-specific reminders
- Trigger additional automation
- Send notifications to external services

## Custom Scripts

### Backup Script

Create a script to backup your development environment:

```bash
#!/bin/bash
# Example: $HOME/.local/bin/backup_dev.sh

echo "Backing up dotfiles..."
cp ~/.zshrc ~/Dropbox/dotfiles/
cp ~/.vimrc ~/Dropbox/dotfiles/
# Add more backup commands
echo "Backup complete!"
```

Then configure:
```bash
export GOODMORNING_BACKUP_SCRIPT="$HOME/.local/bin/backup_dev.sh"
```

## Background Updates

The script runs these updates in the background:

1. **Backup script** (if configured) - Runs your custom backup
2. **Homebrew update** - Updates package index
3. **Homebrew upgrade** - Upgrades installed packages
4. **brew doctor** - Checks for issues
5. **Claude Code update** - Updates Claude Code via npm
6. **Vim plugins update** - Pulls latest changes for git-based plugins

All output is logged to `/tmp/goodmorning_updates_$$.log` and you'll receive a macOS notification when complete.

## Personalized Learning Tips

If Claude Code is installed, the script generates personalized learning tips based on your recent git commits. It scans directories specified in `GOODMORNING_PROJECT_DIRS` for repositories with commits in the last 7 days.

To customize which directories are scanned:

```bash
export GOODMORNING_PROJECT_DIRS="$HOME/workspace:$HOME/personal-projects"
```

## Platform Notes

This script is designed for macOS and uses:

- `say` command for voice greeting
- `osascript` for calendar/reminders integration
- macOS notification system

For Linux/WSL, you may need to modify or disable these sections.

## Troubleshooting

### Calendar events not showing

Install icalBuddy:
```bash
brew install ical-buddy
```

### Historical events not showing

Install jq:
```bash
brew install jq
```

### Learning tips not generating

Install Claude Code from https://claude.ai/code

### Updates not running in background

Check the log file for errors:
```bash
cat /tmp/goodmorning_updates_*.log
```

### Vim plugins not updating

Verify the plugins directory exists:
```bash
ls -la $GOODMORNING_VIM_PLUGINS_DIR
```

## Testing

This project uses [ShellSpec](https://shellspec.info/) for BDD-style testing.

### Running Tests

```bash
# Install ShellSpec (macOS)
brew install shellspec

# Run all tests
shellspec

# Run specific spec file
shellspec spec/lib/colors_spec.sh

# Run tests in watch mode
shellspec --watch
```

### Test Structure

Tests are organized by feature in the `spec/` directory:
- `spec/goodmorning/` - Main script functionality
- `spec/setup/` - Setup script tests
- `spec/lib/` - Library module tests

All tests use ShellSpec's BDD syntax with `Describe`, `It`, `When`, and `The` blocks for readable test specifications.

## Contributing

Contributions are welcome! Here are some ways you can help:

**Bug Reports & Feature Requests:**
- Open an issue describing the bug or feature
- Include your macOS version and zsh version
- For bugs, include steps to reproduce

**Code Contributions:**
1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes following the code style in CONTRIBUTING.md
4. Run the test suite: `shellspec`
5. Commit with clear messages
6. Push and open a Pull Request

**Common Customization Ideas:**
- Add your own information sources (news APIs, stock prices, etc.)
- Integrate with different calendar/task management systems
- Add custom health checks for your services
- Create additional display sections
- Improve offline mode functionality

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## Support

**Questions or Issues?**
- Check existing [GitHub Issues](https://github.com/YOUR_USERNAME/goodmorning-script/issues)
- Review the [Troubleshooting](#troubleshooting) section
- Open a new issue if you can't find an answer

**Useful Resources:**
- [ShellSpec Documentation](https://shellspec.info/) - For writing tests
- [Zsh Documentation](https://zsh.sourceforge.io/Doc/) - For shell scripting
- [icalBuddy](https://hasseg.org/icalBuddy/) - For calendar integration

## License

MIT License - See [LICENSE](LICENSE) for details.

Copyright (c) 2025 Greg McGuirk
