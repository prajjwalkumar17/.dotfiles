#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script to stow all dotfiles
DOTFILES="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo -e "${RED}GNU Stow is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if dotfiles directory exists
if [ ! -d "$DOTFILES" ]; then
    echo -e "${RED}Dotfiles directory not found at $DOTFILES${NC}"
    exit 1
fi

# Navigate to dotfiles directory
cd "$DOTFILES" || exit 1

# Create .config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Function to backup existing file/directory
backup_existing() {
    local target=$1
    if [ -e "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        echo -e "${BLUE}Backing up existing $target to $BACKUP_DIR${NC}"
        mv "$target" "$BACKUP_DIR/"
    fi
}

# Function to stow a directory
stow_directory() {
    local dir=$1
    echo -e "${YELLOW}Stowing $dir...${NC}"
    
    # Get list of files/dirs that would be stowed
    mapfile -t files < <(find "$dir" -type f -o -type l | sed "s|^$dir/||")
    
    # Check and backup existing files
    for file in "${files[@]}"; do
        target="$HOME/$file"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            backup_existing "$target"
        fi
    done
    
    # Remove existing symlinks first
    stow -D "$dir" 2>/dev/null
    
    # Create new symlinks
    if stow "$dir" 2>/dev/null; then
        echo -e "${GREEN}Successfully stowed $dir${NC}"
        return 0
    else
        echo -e "${RED}Failed to stow $dir${NC}"
        return 1
    fi
}

# List of directories to stow
# Excluding .git directory and backup directory
directories=$(find . -maxdepth 1 -type d ! -name ".*" -printf "%f\n")

# Counter for successful and failed operations
success=0
failed=0
failed_dirs=()

# Stow each directory
for dir in $directories; do
    if stow_directory "$dir"; then
        ((success++))
    else
        ((failed++))
        failed_dirs+=("$dir")
    fi
done

# Print summary
echo -e "\n${GREEN}Stowing complete!${NC}"
echo -e "Successfully stowed: ${GREEN}$success${NC} directories"
if [ $failed -gt 0 ]; then
    echo -e "Failed to stow: ${RED}$failed${NC} directories: ${RED}${failed_dirs[*]}${NC}"
    if [ -d "$BACKUP_DIR" ]; then
        echo -e "${BLUE}Backed up existing files to: $BACKUP_DIR${NC}"
    fi
fi
