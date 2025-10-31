#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
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

# Create symlinks
ln -sf "$(pwd)/niri" ~/.config/
ln -sf "$(pwd)/waybar" ~/.config/
ln -sf "$(pwd)/kitty" ~/.config/
ln -sf "$(pwd)/scripts" ~/.config/

echo "Installation and setup complete!"