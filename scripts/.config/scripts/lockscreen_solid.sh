#!/usr/bin/env bash

# Define wallpaper directory
WALLPAPER_DIR="$HOME/.dotfiles/Wallpaper/Wallpaper/"

# Select a random wallpaper that is not currently loaded
CURRENT_WALL=$(hyprctl hyprpaper listloaded)
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) ! -name "$(basename "$CURRENT_WALL")" | shuf -n 1)

swaylock \
    --image "$WALLPAPER" \
    --clock \
    --indicator \
    --indicator-radius 200 \
    --indicator-thickness 20 \
    --ring-color bb00cc \
    --key-hl-color 880033 \
    --line-color 00000000 \
    --inside-color 00000088 \
    --separator-color 00000000 \
