#!/bin/bash

arg_horizontal=0

while getopts "H" opt; do
    case $opt in
        H)
            arg_horizontal=1
            ;;
        *)
            echo "Usage: $0 [options]"
            echo "Arguments:"
            echo "  -H  Enable horizontal scrolling."
            ;;
    esac
done

POINTER_ID=${1:-10}

ENABLED=$(xinput --list-props "$POINTER_ID" | grep \(300\) | awk '{print $5}')

function finish {
    rm /tmp/"$USER"-toggle-scrollwheel-emulation.pid
}

trap finish EXIT

if [ -e /tmp/"$USER"-toggle-scrollwheel-emulation.pid ]; then
    pkill -F /tmp/"$USER"-toggle-scrollwheel-emulation.pid
    rm /tmp/"$USER"-toggle-scrollwheel-emulation.pid
fi

echo "$$" > /tmp/"$USER"-toggle-scrollwheel-emulation.pid

xinput --set-prop "$POINTER_ID" "Evdev Wheel Emulation Button" 0

# For horizontal scrolling
if [[ "$arg_horizontal" -eq 1 ]]; then
    xinput --set-prop "$POINTER_ID" "Evdev Wheel Emulation Axes" 6 7 4 5
else
    xinput --set-prop "$POINTER_ID" "Evdev Wheel Emulation Axes" 0 0 4 5
fi

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
