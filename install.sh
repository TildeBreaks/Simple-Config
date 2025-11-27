#!/bin/bash

# A script to set up the Niri desktop environment with a dynamic theme.

# --- Helper Functions ---
# Function to print a formatted message
print_msg() {
    echo -e "\\n\\e[1;32m[INFO]\\e[0m $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Package Installation ---
# List of essential packages
packages=(
    "niri"
    "quickshell"
    "waybar"
    "kitty"
    "thunar"
    "dunst"
    "swww"
    "zenity"
    "inter-font"
)

# List of packages from the AUR
aur_packages=(
    "zen-browser"
    "matugen-bin"
)

# Install yay if it's not already installed
if ! command_exists yay; then
    print_msg "yay not found. Installing..."
    git clone https://aur.archlinux.org/yay.git
    (cd yay && makepkg -si --noconfirm)
    rm -rf yay
fi

# Install packages
print_msg "Installing essential packages..."
sudo pacman -S --needed --noconfirm "${packages[@]}"

print_msg "Installing AUR packages..."
yay -S --needed --noconfirm "${aur_packages[@]}"


# --- Configuration Setup (Non-Destructive) ---
print_msg "Setting up configuration files..."
CONFIG_DIR="$HOME/.config"
REPO_DIR=$(pwd)

# Function to safely create a symbolic link
safe_symlink() {
    local source="$1"
    local target="$2"

    if [ -e "$target" ]; then
        print_msg "Configuration already exists at $target. Skipping."
    else
        ln -s "$source" "$target"
        echo "Linked $source to $target."
    fi
}

# Create symlinks for the configuration directories
safe_symlink "$REPO_DIR/niri" "$CONFIG_DIR/niri"
safe_symlink "$REPO_DIR/waybar" "$CONFIG_DIR/waybar"
safe_symlink "$REPO_DIR/kitty" "$CONFIG_DIR/kitty"
safe_symlink "$REPO_DIR/dunst" "$CONFIG_DIR/dunst"
safe_symlink "$REPO_DIR/scripts" "$CONFIG_DIR/scripts"

# Create symlink for the matugen configuration
mkdir -p "$CONFIG_DIR/matugen"
safe_symlink "$REPO_DIR/matugen.toml" "$CONFIG_DIR/matugen/matugen.toml"


# --- Final Steps ---
print_msg "Installation complete!"
echo "Please log out and select 'Niri' from your login manager."
echo "You can change the wallpaper and theme by clicking the image icon in the top-right of the Waybar."
