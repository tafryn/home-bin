#!/bin/bash

LAPTOP=DP-2
LEFT_MON=DP-0.2
CENTER_MON=DP-0.1
RIGHT_MON=DP-0.3

#xrandr --output $CENT_MON --primary --rotate left
#xrandr --output $RIGHT_MON --rotate left --right-of $CENT_MON
#xrandr --output $LEFT_MON --rotate left --left-of $CENT_MON
#xrandr --output $LAPTOP --left-of $LEFT_MON
#xrandr --output $LAPTOP --pos 0x800
#xrandr --output $CENT_MON --primary --rotate left --output $RIGHT_MON --rotate left --right-of DP-3 --output $LEFT_MON --rotate left --left-of DP-3 --output $LAPTOP --pos 0x800

xrandr --output "$LEFT_MON" --off
xrandr --output "$CENTER_MON" --off
xrandr --output "$RIGHT_MON" --off
xrandr --output "$LAPTOP" --fb 1920x1080
xrandr --output "$LAPTOP" --panning "0x0+0+0/0x0+0+0/0/0/0/0"
xrandr --output "$LAPTOP" --primary --pos 0x0 --mode 1920x1080 --output "$LEFT_MON" --pos 1920x0 --mode 1920x1080 --rotate left --output "$CENTER_MON" --pos 3000x0 --mode 1920x1080 --rotate left --output "$RIGHT_MON" --pos 4080x0 --mode 1920x1200 --rotate right 
