#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Exaclty 1 argument should be passed"
    exit 1
fi

device=$1

sed -E -i "s/([ \t]+$device[ \t]+.*[ \t]+\*)enabled/\1disabled/" 'example-wakeup'

# леко чупи спейсовете ама бачка