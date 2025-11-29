#!/usr/bin/env zsh

###############################################################################
# Completion Callback Template for Good Morning Script
###############################################################################
#
# This is a template file. To use completion callback functionality:
#
# 1. Copy this file to your preferred location:
#    cp examples/completion-callback-template.sh ~/.config/zsh/scripts/my-callback.sh
#
# 2. Edit the copied file to add your post-briefing actions:
#    - Open applications (IDE, browser, email)
#    - Navigate to work directories
#    - Start development servers or Docker containers
#    - Display custom work context or reminders
#    - Run git status checks across projects
#    - Launch tmux sessions
#    - Perform service health checks
#
# 3. Set the environment variable to use your script:
#    export GOODMORNING_COMPLETION_CALLBACK="$HOME/.config/zsh/scripts/my-callback.sh"
#
# 4. Make your script executable:
#    chmod +x ~/.config/zsh/scripts/my-callback.sh
#
# This script runs AFTER the morning briefing completes.
# See the project README for more examples and ideas.
###############################################################################

echo "This is the completion callback template."
echo "Copy and customize this file to add your own post-briefing actions."
echo ""
echo "Recommendations:"
echo '  - curl -s "https://code.google.com/archive/p/badwordslist/downloads" | say'
echo ""

return 0
