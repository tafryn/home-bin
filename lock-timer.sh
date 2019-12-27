#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "No timer command supplied. Exiting..."
    exit
fi

dir="$(dirname "$0")"

pkill xidlehook

if [ -e /tmp/xidlehook.sock ]; then
    rm /tmp/xidlehook.sock
fi

export PRIMARY_DISPLAY="$(xrandr | grep primary | cut -d ' ' -f 1)"

read -r -d '' lock << EOF
    # Pause notifications
    pkill dunst -USR1

    $1

    # Start notifications
    pkill dunst -USR2
EOF
export lock

    # --not-when-audio \
xidlehook \
    --not-when-fullscreen \
    --socket /tmp/xidlehook.sock \
    --timer 600 \
        'xrandr --output "$PRIMARY_DISPLAY" --brightness .1' \
        'xrandr --output "$PRIMARY_DISPLAY" --brightness 1' \
    --timer 10 \
        'xrandr --output "$PRIMARY_DISPLAY" --brightness 1 && /bin/sh -c "$lock"' \
        '' \
    --timer 60 \
        'xset dpms force off' \
        '' \
    --timer 600 \
        'systemctl suspend' \
        '' \
