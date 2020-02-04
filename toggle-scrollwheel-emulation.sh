#!/bin/bash

POINTER_ID=${1:-10}

ENABLED=$(xinput --list-props "$POINTER_ID" | grep \(300\) | awk '{print $5}')

if [ -e /tmp/"$USER"-toggle-scrollwheel-emulation.pid ]; then
    pkill -F /tmp/"$USER"-toggle-scrollwheel-emulation.pid
    rm /tmp/"$USER"-toggle-scrollwheel-emulation.pid
else
    echo "$$" > /tmp/"$USER"-toggle-scrollwheel-emulation.pid
fi

xinput --set-prop "$POINTER_ID" "Evdev Wheel Emulation Button" 0

# For horizontal scrolling
#xinput --set-prop "$POINTER_ID" "Evdev Wheel Emulation Axes" 6 7 4 5

if [[ "$ENABLED" -eq 0 ]]; then
    xinput --set-prop "$POINTER_ID" "Evdev Wheel Emulation" 1
    while read -r line; do
        if [ "$line" == "button release 1" ]; then
            xinput --set-prop "$POINTER_ID" "Evdev Wheel Emulation" 0
            break
        fi
    done < <(xinput test "$POINTER_ID")
else
    xinput --set-prop "$POINTER_ID" "Evdev Wheel Emulation" 0
fi
