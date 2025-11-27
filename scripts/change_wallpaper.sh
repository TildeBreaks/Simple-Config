#!/bin/bash

# 1. Select a wallpaper using Zenity's file picker.
# We'll look in the user's Pictures/Wallpapers directory by default.
wallpaper=$(zenity --file-selection --title="Select a Wallpaper" --filename="$HOME/Pictures/Wallpapers/")

# Exit if no file is selected.
if [ "$?" -ne 0 ]; then
    echo "No wallpaper selected. Exiting."
    exit 1
fi

# 2. Set the new wallpaper using swww.
# Initialize the swww daemon if it's not running.
swww query || swww init

# Change the wallpaper with a nice transition effect.
swww img "$wallpaper" --transition-type wipe --transition-angle 30 --transition-step 90

# 3. Generate and apply the new theme with matugen.
# Matugen will use the templates located in the config directories.
matugen image "$wallpaper"

# 4. Reload Waybar to apply the new stylesheet.
# This sends a signal to the running Waybar process to reload its config and CSS.
pkill -SIGUSR2 waybar

echo "Wallpaper and theme updated successfully."
