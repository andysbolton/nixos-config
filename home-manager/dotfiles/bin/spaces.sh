#!/bin/bash

id=$(
	yabai -m query --windows |
		jq -r 'sort_by(.display, .space) | .[] | "\(.display). - \(((.space - 1) % 7) + 1) | \(.app) | \(.title) | \(.id)"' |
		fzf |
		awk -F ' | ' '{print $NF}'
)

[[ -z "$id" ]] && exit 0

yabai -m window --focus "$id"
