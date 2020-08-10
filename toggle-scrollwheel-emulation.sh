#!/bin/bash

arg_horizontal=0

function usage {
    echo "Usage: $(basename -- "$0") [options] pointer_name"
    echo "Arguments:"
    echo "  -H  Enable horizontal scrolling."
    echo ""
    echo "The pointer_name can be discovered by looking at the output of 'xinput list'."
    echo "Either the numeric ID or the string can be used, but the string should be"
    echo "preferred because the numeric ID can change under certain circumstances."
}

while getopts "H" opt; do
    case $opt in
        H)
            arg_horizontal=1
            ;;
        *)
            usage
            exit
            ;;
    esac
done

shift $((OPTIND-1))

# Identify the desired pointer device id by examining the output of "xinput list".
POINTER_ID=$(xinput | grep "$1" | grep -m 1 -oP '(?<=id=)[[:digit:]]*')

ENABLED=$(xinput --list-props "$POINTER_ID" | grep "Evdev Wheel Emulation (" | awk '{print $5}')

function finish {
    xinput --set-prop "$POINTER_ID" "Evdev Wheel Emulation" 0
    killall xinput
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
        if [ "$line" == "detail: 1" ]; then
            break
        fi
    done < <(xinput --test-xi2 --root "$POINTER_ID" | grep --line-buffered -E 'detail: 1')
fi
