#!/bin/bash

# A wrapper for vimpager that calculates the length of the input, be it
# file or pipe, and outputs it to vimpager if paging is needed and vimcat
# if paging is not needed.

if [ $# -ge 1 -a -f "$1" ]; then
    INPUT=$(cat $1)
else
    INPUT=$(cat "-")
fi

TERM_LINES=$(tput lines)

INPUT_LINES=$(echo -n "$INPUT" | wc -l | cut -d' ' -f1)

if [ "$TERM_LINES" -gt "$INPUT_LINES" ]; then
    echo -n "$INPUT" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | vimcat -u ~/.vimpagerrc
else
    echo -n "$INPUT" | vimpager
fi
