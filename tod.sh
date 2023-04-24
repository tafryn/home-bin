#!/usr/bin/env bash

if [ -z "$(command -v tod)" ]; then
    echo "Could not find tod binary"
    exit 1
fi

if [ "$ROFI_RETV" = "0" ]; then
    echo "Input a task..."
    exit 0
elif [ "$ROFI_RETV" = "1" ]; then
    exit 0
elif [ "$ROFI_RETV" = "2" ]; then
    tod -t "tod $@" >/dev/null
    exit 0
fi
