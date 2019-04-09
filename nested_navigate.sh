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

descendents_of () {
    local children
    children=$(ps -o pid= --ppid "$1")

    for pid in $children; do
        descendents_of "$pid"
    done

    echo "$children"
}

has_child () {
    local pid=$1 process=$2
    ps -h -o command -"$pid" | grep -q "$process"
}

pane_at_edge() {
  direction=$1

  case "$direction" in
     "U") 
       coord='top'
       op='<='
     ;;
     "D")
       coord='bottom'
       op='>='
     ;;
     "L")
       coord='left'
       op='<='
     ;;
     "R")
       coord='right'
       op='>='
     ;;
  esac

  cmd="#{pane_id}:#{pane_$coord}:#{?pane_active,_active_,_no_}"
  panes=$(tmux list-panes -F "$cmd")
  active_pane=$(echo "$panes" | grep _active_)
  # active_pane_id=$(echo "$active_pane" | cut -d: -f1)
  active_coord=$(echo "$active_pane" | cut -d: -f2)
  coords=$(echo "$panes" | cut -d: -f2)

  if [ "$op" == ">=" ]; then
    test_coord=$(echo "$coords" | sort -nr | head -n1)
    at_edge=$(( active_coord >= test_coord ? 0 : 1 ))
  else
    test_coord=$(echo "$coords" | sort -n | head -n1)
    at_edge=$(( active_coord <= test_coord ? 0 : 1 ))
  fi;
  return $at_edge
}

select_pane_no_wrap() {
  direction=$1
  at_edge=$(pane_at_edge "$direction")
  if [ "$at_edge" = 0 ] ; then
    tmux select-pane "-$direction"
  else
    :
  fi
}

# Variable setup

TERMINAL_CLASS_NAMES=(xterm URxvt Alacritty Gnome-terminal konsole)

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
FOCUSED_CLASS_NAMES=$(xprop -id "$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2)" WM_CLASS | grep -o '".*"' | tr -d '",')

FOCUSED_TITLE=$(xprop -id "$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2)" _NET_WM_NAME | grep -o '".*"' | tr -d '",')

FOCUSED_PID=$(xprop -id "$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2)" _NET_WM_PID | grep -o '[[:digit:]]\+')

for class_name in $FOCUSED_CLASS_NAMES; do
    if contains_element "$class_name" "${TERMINAL_CLASS_NAMES[@]}"; then
        TERMINAL_FOCUSED=true
    fi
done

# Determine navigation type
TMUX_IN_FOCUSED_TERMINAL=false
TYPE=i3

if $TERMINAL_FOCUSED; then
    for child in $(descendents_of "$FOCUSED_PID"); do
        if has_child "$child" "tmux"; then
            TMUX_IN_FOCUSED_TERMINAL=true

            if pane_at_edge "$DIRECTION"; then
                TYPE=i3
            else
                TYPE=tmux
            fi
        fi
    done

	if echo "$FOCUSED_TITLE" | grep -q VIM && ! $VIM_CALL; then
        TYPE=vim
	fi
else
	TYPE=i3
fi

contains_element "$TYPE" "${NAVIGATION_TYPES[@]}" || exit 1


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
        xdotool key --clearmodifiers --window \""$(xdotool getactivewindow)"\" ctrl+"$(echo "$DIRECTION" | tr 'LDUR' 'hjkl')"
    fi
	;;
esac
