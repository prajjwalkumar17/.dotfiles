#!/usr/bin/env bash

# Start swww if not already running
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww-daemon &
    sleep 1  # Wait for swww to initialize
fi

# Select a random wallpaper from ~/Wallpaper
WALLPAPER=$(find ~/Wallpaper -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | shuf -n 1)

# Get connected monitors
MONITOR1="DP-2"
MONITOR2="HDMI-A-1"

# Set wallpaper for main monitor (landscape)
swww img "$WALLPAPER" -o "DP-2" --transition-type grow

# Set wallpaper for second monitor (vertical)
swww img "$WALLPAPER" -o "HDMI-A-1" --resize crop --transition-type grow
