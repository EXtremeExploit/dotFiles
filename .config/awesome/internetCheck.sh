#!/bin/bash

lastFailed=0

while true; do
    me="$(basename "$0")"
    running=$(ps h -C "$me" | grep -wv $$ | wc -l)
    [[ $running > 1 ]] && exit

    # Send one ping with a 3-second timeout and capture the exit status
    ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1
    status=$?

    if [ $status -eq $lastWasGood ]; then
        # Check the exit status of the ping command
        if [ $status -eq 0 ]; then
            # Add your logic for a successful ping here
            dbus-send --session --type=signal /org/awesomewm/CustomPath org.awesomewm.CustomInterface.MyCustomMessage string:"internet" string:"good internet"
            lastFailed=0
        else
            # Add your logic for a failed ping here
            dbus-send --session --type=signal /org/awesomewm/CustomPath org.awesomewm.CustomInterface.MyCustomMessage string:"internet" string:"bad internet"
            lastFailed=1

        fi
    fi

    sleep 10
    # notify-send $running
done
