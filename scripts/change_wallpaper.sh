#!/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Select a wallpaper using a file picker
SELECTED_WALLPAPER=$(zenity --file-selection --title="Select a Wallpaper" --filename="$WALLPAPER_DIR/")

# Check if a wallpaper was selected
if [ -z "$SELECTED_WALLPAPER" ]; then
    echo "No wallpaper selected. Exiting."
    exit 0
fi

# Set the wallpaper using swww
swww img "$SELECTED_WALLPAPER" --transition-type any

# Run matugen to generate and apply the theme
matugen image "$SELECTED_WALLPAPER" -t niri -t waybar -t kitty

# Reload configurations
niri msg action reload-config
pkill -SIGUSR2 waybar
pkill -SIGUSR1 kitty