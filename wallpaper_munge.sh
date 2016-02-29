#!/bin/bash

FILENAME=$(basename "$1")
EXTENSION="${FILENAME##*.}"
FILENAME="${FILENAME%.*}"

add_gaps () {
    #local GAP1=100
    local GAP_ONE=0
    local GAP_TWO=80
    local GAP_THREE=20

    local FILENAME=$(basename "$1")
    local EXTENSION="${FILENAME##*.}"
    local FILENAME="${FILENAME%.*}"

    convert "$1" -background black -chop "$GAP_ONE"x0+3000+0 "a_$FILENAME.$EXTENSION"
    convert "a_$FILENAME.$EXTENSION" -background black -chop "$GAP_TWO"x0+3000+0 "b_$FILENAME.$EXTENSION"
    convert "b_$FILENAME.$EXTENSION" -background black -chop "$GAP_THREE"x0+4080+0 "c_$FILENAME.$EXTENSION"

    # Clean-up
    cp "c_$FILENAME.$EXTENSION" "chopped_$FILENAME.$EXTENSION"
    rm "a_$FILENAME.$EXTENSION" "b_$FILENAME.$EXTENSION" "c_$FILENAME.$EXTENSION"
}

# Expand image so that content is centered on external monitors.
main () {
    convert "$1" -background black -splice 1920x0 "mod_$FILENAME.$EXTENSION"

    add_gaps "mod_$FILENAME.$EXTENSION"
}

main

