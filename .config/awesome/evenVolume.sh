#!/bin/bash
vol=$(pactl get-sink-volume 0 | awk '{print $5}' | sed -e 's/[^0-9]*//g')
if [[ $(($vol % 2)) -ne 0 ]]
then
    pactl set-sink-volume 0 -1%
fi
