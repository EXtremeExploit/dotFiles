#!/bin/bash

arg="$1"

function maimSelectionClipboard() {
	maim -s | xclip -selection clipboard -t image/png
}

function maimSelectionClipboardFile() {
	local date=$(date +%Y-%m-%d-%R-%S-%N)
	maim -s ~/$date.png && xclip -selection clipboard -t image/png ~/$date.png
}

function regionHandler() {
	maim -u | feh - &
	local feh_pid=$!

	# wait for feh to start
	while [ -z "$(xdotool search --pid "$feh_pid")" ]; do
		sleep 0.1
	done

	printf "arg $arg"

	# get window ID of feh
	local wid="$(xdotool search --pid "$feh_pid")"

	# fullscreen feh and move top-left (works with multi-monitor)
	xdotool windowsize "$wid" 100% 100%
	xdotool windowmove "$wid" 0 0

	# take the new screenshot by selection, pipe to clipboard
	if [[ $arg == "clipboard" ]]; then
		maimSelectionClipboard
	elif [[ $arg == "file" ]]; then
		maimSelectionClipboardFile
	fi

	# kill feh
	kill "$feh_pid"
}

regionHandler
