#!/usr/bin/env bash

default_pane_resize="5"

get_keymap() {
	if [[ -z ${DISPLAY+x} ]]; then
		path_to_localectl=$(which localectl)
		if [[ -x "$path_to_localectl" ]]; then
			KEYMAP=$(localectl status | awk '/VC/{print $3}')
		elif [ -f "/etc/sysconfig/keyboard" ]; then
			KEYMAP=$(cat /etc/sysconfig/keyboard | awk -F '"' '/LAYOUT/{print $2}')
		elif [ -f "/etc/vconsole.conf" ]; then
			KEYMAP=$(cat /etc/vconsole.conf | awk -F '"' '/KEYMAP/{print $2}')
		elif [ -f "/etc/default/keyboard" ]; then
			KEYMAP=$(cat /etc/default/keyboard | awk -F '"' '/XKBLAYOUT/{print $2}')
		else
			KEYMAP="us"
		fi
	else
		KEYMAP=$(setxkbmap -query | awk '/variant/{print $2}')
	fi
}

get_keymap

echo $KEYMAP
