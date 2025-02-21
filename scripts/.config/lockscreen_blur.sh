#!/usr/bin/env bash

# Take a screenshot and blur it
MONITOR="DP-2"
grim -o "$MONITOR" /tmp/lockscreen.png

# Lock screen with blurred image
swaylock \
    --image /tmp/lockscreen.png \
    --clock \
    --indicator \
    --indicator-radius 200 \
    --indicator-thickness 20 \
    --effect-blur 7x5 \
    --effect-vignette 0.5:0.5 \
    --ring-color bb00cc \
    --key-hl-color 880033 \
    --line-color 00000000 \
    --inside-color 00000088 \
    --separator-color 00000000 \
