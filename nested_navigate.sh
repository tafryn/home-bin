#!/usr/bin/env bash

# Helper functions
contains_element () {
    local e match="$1"
    shift
    for e; do [[ "$e" == "$match" ]] && return 0; done
    return 1
}

index_of () {
    local e element="$1"
    shift
    arr=("$@")
    for i in "${!arr[@]}"; do
        if [[ "${arr[$i]}" = "${element}" ]]; then
            echo "$i";
        fi
    done
}

has_descendant () {
    local children
    children=$(< /proc/"$1"/task/"$1"/children)

    for pid in $children; do
        if [[ "$(< /proc/"$pid"/cmdline)" =~ $2 ]]; then
            return 0
        else
            if has_descendant "$pid" "$2"; then
                return 0
            fi
        fi
    done

    return 1
}

pane_at_edge() {
    direction=$1

    case "$direction" in
        "U") 
            coord='top'
        ;;
        "D")
            coord='bottom'
        ;;
        "L")
            coord='left'
        ;;
        "R")
            coord='right'
        ;;
    esac

    panes=$(tmux list-panes -F "#{?pane_active,_active_,_no_}:#{?pane_at_$coord,0,1}" | sort | head -1)
    
    return "${panes##*:}"
}

# Variable setup

TERMINAL_CLASS_NAMES=(Alacritty Gnome-terminal konsole URxvt xterm)

NAVIGATION_DIRECTIONS=(L D U R)

LONG_NAVIGATION_DIRECTIONS=(left down up right)

NAVIGATION_TYPES=(i3 tmux vim)

TERMINAL_FOCUSED=false

# Input validation
[ "$#" -ge 1 ] || exit 1

OPTIND=1
VIM_CALL=false

while getopts "V" opt; do
	case "$opt" in
	V)
		VIM_CALL=true
		;;
	*)
		;;
	esac
done

shift $((OPTIND-1))

contains_element "$1" "${NAVIGATION_DIRECTIONS[@]}" || exit 1

DIRECTION="$1"

# Check if terminal is focused
ACTIVE_WINDOW_RAW=$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW)
ACTIVE_WINDOW_ID="0x"${ACTIVE_WINDOW_RAW#*0x}

readarray -n 3 XPROP_LINES< <(xprop -id "$ACTIVE_WINDOW_ID" WM_CLASS _NET_WM_NAME _NET_WM_PID); \
    FOCUSED_CLASS_NAME=${XPROP_LINES[0]#*\"}; FOCUSED_CLASS_NAME=${FOCUSED_CLASS_NAME%%\"*};  \
    FOCUSED_TITLE=${XPROP_LINES[1]#*\"}; FOCUSED_TITLE=${FOCUSED_TITLE%\"*};  \
    FOCUSED_PID=${XPROP_LINES[2]##*\ }; FOCUSED_PID=${FOCUSED_PID%$'\n'}

if contains_element "$FOCUSED_CLASS_NAME" "${TERMINAL_CLASS_NAMES[@]}"; then
    TERMINAL_FOCUSED=true
fi

# Determine navigation type
TMUX_IN_FOCUSED_TERMINAL=false
TYPE=i3

if $TERMINAL_FOCUSED; then
    if has_descendant "$FOCUSED_PID" "tmux"; then
        TMUX_IN_FOCUSED_TERMINAL=true

        if pane_at_edge "$DIRECTION"; then
            TYPE=i3
        else
            TYPE=tmux
        fi
    fi

	if [[ "$FOCUSED_TITLE" =~ VIM ]] && ! $VIM_CALL; then
        TYPE=vim
	fi
else
	TYPE=i3
fi

contains_element "$TYPE" "${NAVIGATION_TYPES[@]}" || exit 1

# Run navigation command
case "$TYPE" in
i3)
    i3-msg -t run_command focus "${LONG_NAVIGATION_DIRECTIONS[$(index_of "$DIRECTION" "${NAVIGATION_DIRECTIONS[@]}")]}" >/dev/null
	;;
tmux)
    tmux select-pane -"$(echo "$DIRECTION" | tr 'LDUR' 'LDUR')"
	;;
vim)
    if $TMUX_IN_FOCUSED_TERMINAL; then
        tmux send-keys C-"$(echo "$DIRECTION" | tr 'LDUR' 'hjkl')"
    else
        # xdotool keyup "$(echo "$DIRECTION" | tr 'LDUR' 'hjkl')" # qwerty shortcuts
        xdotool keyup "$(echo "$DIRECTION" | tr 'LDUR' 'dhtn')" # dvorak shortcuts
        xdotool key --clearmodifiers --window \""$(xdotool getactivewindow)"\" ctrl+"$(echo "$DIRECTION" | tr 'LDUR' 'hjkl')"
    fi
	;;
esac
