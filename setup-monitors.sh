LAPTOP=DP-4
LEFT_MON=DP-6
CENT_MON=DP-0
RIGHT_MON=VGA-0
#xrandr --output $CENT_MON --primary --rotate left
#xrandr --output $RIGHT_MON --rotate left --right-of $CENT_MON
#xrandr --output $LEFT_MON --rotate left --left-of $CENT_MON
#xrandr --output $LAPTOP --left-of $LEFT_MON
#xrandr --output $LAPTOP --pos 0x800
#xrandr --output $CENT_MON --primary --rotate left --output $RIGHT_MON --rotate left --right-of DP-3 --output $LEFT_MON --rotate left --left-of DP-3 --output $LAPTOP --pos 0x800
xrandr --output $LAPTOP --pos 0x800 --output $LEFT_MON --rotate left --pos 1920x0 --output $CENT_MON --rotate left --pos 3000x0 --primary --output $RIGHT_MON --rotate left --pos 4080x0
