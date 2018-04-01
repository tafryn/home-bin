#!/bin/bash

if [ ! -x "$(command -v convert)" ]; then
    i3lock -e
else
    # Figure out the current resolution of the screen
    RESOLUTION=$(xrandr -q | awk -F'current' -F',' 'NR==1 {gsub("( |current)","");print $2}')

    # Lock screen image generation command
    MAKE_LOCK_IMAGE="convert -quality 100 -resize $RESOLUTION^ -gravity center -crop $RESOLUTION+0+0 $HOME/.wallpaper $HOME/.lock_image.png"

    # Generate the lock screen image if necessary
    if [ -e ~/.lock_image.png ]; then
        IMAGE_RESOLUTION=$(identify ~/.lock_image.png | awk '{print $3}')
        if [[ "$RESOLUTION" != "$IMAGE_RESOLUTION" ]]; then
            $($MAKE_LOCK_IMAGE)
        fi
    else
        $($MAKE_LOCK_IMAGE)
    fi

    # Lock screen displaying the image
    i3lock -e -i $HOME/.lock_image.png
fi

# Turn the screen off after a delay if still locked
sleep 60; pgrep i3lock && xset dpms force off
