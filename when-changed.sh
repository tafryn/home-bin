#!/bin/bash

FILE=$1

shift

PROG=$1

shift

ARGS="$@"

echo "Watching $FILE. Will run \"$PROG $ARGS\""

while true; do
    CHANGE=$(inotifywait -q -e close_write,moved_to,create .)
    CHANGED_FILE=${CHANGE##* }
    echo $CHANGED_FILE changed.
    if [ "$CHANGED_FILE" = "$FILE" ]; then `$PROG $ARGS`; fi
done
