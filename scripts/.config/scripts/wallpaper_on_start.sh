#!/usr/bin/env bash

# # Start swww if not already running
# if ! pgrep -x "swww-daemon" > /dev/null; then
#     swww-daemon &
#     sleep 1  # Wait for swww to initialize
# fi
#
# # Select a random wallpaper from ~/Wallpaper
# WALLPAPER=$(find ~/Wallpaper -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | shuf -n 1)
#
# # Get connected monitors
# MONITOR1="DP-2"
# MONITOR2="HDMI-A-1"
#
# # Set wallpaper for main monitor (landscape)
# swww img "$WALLPAPER" -o "DP-2" --transition-type grow
#
# # Set wallpaper for second monitor (vertical)
# swww img "$WALLPAPER" -o "HDMI-A-1" --resize crop --transition-type grow
#
#
#
#
# Using hyprpaper as swww isn't able to set properly for vertical screen

# Ensure Hyprpaper is running
if ! pgrep -x "hyprpaper" > /dev/null; then
    hyprpaper &
    sleep 1  # Give Hyprpaper some time to initialize
fi

# Get connected monitors (you can check with `hyprctl monitors`)
MONITOR1="DP-2"
MONITOR2="HDMI-A-1"

# Define wallpaper directory
WALLPAPER_DIR="$HOME/.dotfiles/Wallpaper/Wallpaper/"

# Select a random wallpaper that is not currently loaded
CURRENT_WALL=$(hyprctl hyprpaper listloaded)
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) ! -name "$(basename "$CURRENT_WALL")" | shuf -n 1)
if [ -z "$WALLPAPER" ]; then
    echo "No wallpaper found!"
    exit 1
fi
# Preload and set wallpapers for each monitor
hyprctl hyprpaper preload "$WALLPAPER"
hyprctl hyprpaper wallpaper "$MONITOR1,$WALLPAPER"
hyprctl hyprpaper wallpaper "$MONITOR2,$WALLPAPER"

# (Optional) Unload any unused wallpapers to free memory
hyprctl hyprpaper unload unused

