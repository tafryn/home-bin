#!/usr/bin/env bash

# Profiling
exec 3>&2 2> >(tee /tmp/sample-time.$$.log |
                 sed -u 's/^.*$/now/' |
                 date -f - +%s.%N >/tmp/sample-time.$$.tim)
set -x

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

# This function uses inverted logic to allow for early returns when a matching
# descendant is found.
has_no_descendant () {
    local children value
    children=$(ps -o pid=,comm= --ppid "$1")

    for pid_name in $children; do
        if [[ "$pid_name" =~ $2 ]]; then
            return 1
        else
            value+=has_no_descendant "$([[ "$pid_name" =~ [[:digit:]]* ]]; echo "${BASH_REMATCH[*]}")" "$2"
        fi
    done
    
    return "$value"
}

has_descendant () {
    ! has_no_descendant "$1" "$2"
}

# has_child () {
#     local pid=$1 process=$2
#     ps -h -o command -"$pid" | grep -q "$process"
# }

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
  active_pane=$([[ "$panes" =~ [[:alnum:][:punct:]]*active ]]; echo "${BASH_REMATCH[*]}")
  active_coord=$([[ "$active_pane" =~ :([[:digit:]]*): ]]; echo "${BASH_REMATCH[1]}")
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
ACTIVE_WINDOW_ID=$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2)

readarray -n 3 XPROP_LINES< <(xprop -id "$ACTIVE_WINDOW_ID" WM_CLASS _NET_WM_NAME _NET_WM_PID); \
    FOCUSED_CLASS_NAME=$([[ "${XPROP_LINES[0]}" =~ \"([^\"]+)\" ]]; echo "${BASH_REMATCH[1]}") \
    FOCUSED_TITLE=$([[ "${XPROP_LINES[1]}" =~ \"([^\"]+)\" ]]; echo "${BASH_REMATCH[1]}") \
    FOCUSED_PID=$([[ "${XPROP_LINES[2]}" =~ ([[:digit:]]+) ]]; echo "${BASH_REMATCH[1]}")

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
        xdotool key --clearmodifiers --window \""$(xdotool getactivewindow)"\" ctrl+"$(echo "$DIRECTION" | tr 'LDUR' 'hjkl')"
    fi
	;;
esac

# Profiling
set +x
exec 2>&3 3>&-
