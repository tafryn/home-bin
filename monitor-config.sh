#!/bin/bash

# Home
LAPTOP=${PRIMARY_SCREEN:-DP-2}
LEFT_MON=${LEFT_SCREEN:-DP-1}
CENTER_MON=${CENTER_SCREEN:-DP-4}
RIGHT_MON=${RIGHT_SCREEN:-DP-5}
BOTTOM_MON=${BOTTOM_SCREEN:-DP-3}

CONNECTED=$(xrandr | grep "[^s]connected" | awk '{print $1}')

# Reset to just the main screen on the laptop
xrandr --output "$LEFT_MON" --off \
    --output "$CENTER_MON" --off \
    --output "$RIGHT_MON" --off \
    --output "$BOTTOM_MON" --off \
    --output "$LAPTOP" --fb 1920x1080 --panning "0x0+0+0/0x0+0+0/0/0/0/0"

# Enable and configure external monitors
if [[ " ${CONNECTED[*]} " =~ ${BOTTOM_MON} ]]; then
    echo "Road Warrior"
    xrandr --output "$LAPTOP" --primary --pos 0x0 --mode 1920x1080 \
        --output "$BOTTOM_MON" --auto --below "$LAPTOP"
elif [[ " ${CONNECTED[*]} " =~ DP-4 ]]; then
    echo "Work/Home PLP"
    xrandr --output "$LAPTOP" --primary --pos 0x0 --mode 1920x1080 \
        --output "$RIGHT_MON" --pos -1200x0 --mode 1920x1200 --rotate right \
        --output "$CENTER_MON" --pos -3760x0 --mode 2560x1440 \
        --output "$LEFT_MON" --pos -4960x0 --mode 1920x1200 --rotate left
elif [[ " ${CONNECTED[*]} " =~ DP-0.1 ]]; then
    echo "Docked Triple P"
    xrandr --output "$LAPTOP" --primary --pos 0x0 --mode 1920x1080 \
        --output "$LEFT_MON" --pos 1920x0 --mode 1920x1080 --rotate left \
        --output "$CENTER_MON" --pos 3000x0 --mode 1920x1080 --rotate left \
        --output "$RIGHT_MON" --pos 4080x0 --mode 1920x1200 --rotate right 
fi
