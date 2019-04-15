#!/bin/bash

#set -x

FILES="$(find . -name "*.cc" -o -name "*.h")"

NAME="$(basename "$0")"

WORKINGDIR="$(mktemp -dt "$NAME.XXXXXXXX")"

for FILE in $FILES; do
    mkdir -p "$(dirname "$WORKINGDIR/$FILE")"
    clang-format -style=file "$FILE" > "$WORKINGDIR/$FILE"
    diff -q "$FILE" "$WORKINGDIR/$FILE" 
done
