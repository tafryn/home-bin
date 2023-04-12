#!/bin/bash

outputs=($(xrandr --listactivemonitors | grep -Po '[^ ]*$' | tail -n +2))

echo ${#outputs[@]}

for o in ${outputs[@]}; do
    echo "$o"
done

# Put workspaces 1 4 7 on first available output
for i in 1 4 7; do
    output=${outputs[1 % ${#outputs[@]}]}
    echo "put $i on $output"
    i3-msg [workspace=$i] move workspace to output $output
done

# Put workspaces 2 5 8 on second available output
for i in 2 5 8; do
    output=${outputs[2 % ${#outputs[@]}]}
    echo "put $i on $output"
    i3-msg [workspace=$i] move workspace to output $output
done

# Put workspaces 3 6 9 on third available output
for i in 3 6 9; do
    output=${outputs[3 % ${#outputs[@]}]}
    echo "put $i on $output"
    i3-msg [workspace=$i] move workspace to output $output
done

# Put workspaces 10 11 12 on zeroth output
for i in 10 11 12; do
    output=${outputs[0]}
    echo "put $i on $output"
    i3-msg [workspace=$i] move workspace to output $output
done
