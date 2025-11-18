#!/bin/bash

###############################################################################
# Backup Script Template for Good Morning Script
###############################################################################
#
# This is a template file. To use backup functionality:
#
# 1. Copy this file to your preferred location:
#    cp examples/backup-script-template.sh ~/.config/zsh/scripts/my-backup.sh
#
# 2. Edit the copied file to add your backup logic:
#    - Backup dotfiles (.zshrc, .vimrc, etc.)
#    - Update Vim/Neovim plugins
#    - Sync custom scripts
#    - Backup project-specific files (.env, configs)
#
# 3. Set the environment variable to use your script:
#    export GOODMORNING_BACKUP_SCRIPT="$HOME/.config/zsh/scripts/my-backup.sh"
#
# 4. Make your script executable:
#    chmod +x ~/.config/zsh/scripts/my-backup.sh
#
# See the project README for more examples and ideas.
###############################################################################

echo "Backups and updates script template - replace with your actual logic"
echo ""
echo "Example backup or update tasks:"
echo "  rsync -av ~/.zshrc ~/.vimrc ~/backups/"
echo "  vim +PlugUpdate +qall"
echo ""

exit 0
