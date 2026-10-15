#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/stats/level.sh"

usage=$(top -l 2 | grep -E "^CPU" | tail -1 | awk '{ printf "%.2f", $3 + $5 }')

"$BAR_NAME" -m --set "$NAME" label="${usage}%" label.color="$(level_color "${usage%.*}")"
