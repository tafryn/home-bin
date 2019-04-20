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
xrandr --output "$LAPTOP" --primary --pos 0x340 --output "$LEFT_MON" --rotate left --pos 1920x0 --output "$CENTER_MON" --rotate left --pos 3000x0 --output "$RIGHT_MON" --rotate right --pos 4080x0 
