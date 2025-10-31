#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to back up a directory
backup_dir() {
    local dir=$1
    if [ -d "$dir" ] || [ -L "$dir" ]; then
        local backup_name="${dir}.bak-$(date +%Y-%m-%d_%H-%M-%S)"
        echo "Backing up '$dir' to '$backup_name'"
        mv "$dir" "$backup_name"
    fi
}

# Install dependencies
if command_exists yay; then
    echo "Installing dependencies using yay..."
    yay -S --noconfirm matugen-bin zenity
elif command_exists paru; then
    echo "Installing dependencies using paru..."
    paru -S --noconfirm matugen-bin zenity
elif command_exists cargo; then
    echo "Installing matugen using cargo..."
    cargo install matugen
else
    echo "Error: Could not find yay, paru, or cargo. Please install one of them to continue."
    exit 1
fi

# Create backups and symlinks
backup_dir ~/.config/niri
backup_dir ~/.config/waybar
backup_dir ~/.config/kitty
backup_dir ~/.config/scripts

echo "Creating symlinks..."
ln -sf "$(pwd)/niri" ~/.config/
ln -sf "$(pwd)/waybar" ~/.config/
ln -sf "$(pwd)/kitty" ~/.config/
ln -sf "$(pwd)/scripts" ~/.config/

echo "Installation and setup complete!"
