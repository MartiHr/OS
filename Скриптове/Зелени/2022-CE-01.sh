#!/bin/bash

if [[ $# -ne 3 ]]; then
    echo "Wrong number of arguments. Should be 3"
    exit 1
fi

number=$1
prefix=$2
unit=$3

echo $number | grep -q -E '^[0-9]+(\.[0-9]+$)*$'

if [[ $? -ne 0 ]]; then
    echo "The first argument should be a number"
    exit 2
fi

prefixLine=$(cat 'prefix.csv' | grep -E "^.*,$prefix,.*$")

multiplier=$(echo $prefixLine | cut -d ',' -f 3)
converted=$(echo "$number * $multiplier" | bc)

baseLine=$(cat 'base.csv' | grep -E "^.*,$unit,.*$")
name=$(echo $baseLine | cut -d ',' -f 1)
measure=$(echo $baseLine | cut -d ',' -f 3)

echo "$converted $unit ($name, $measure)"