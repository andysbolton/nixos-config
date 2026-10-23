#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/stats/level.sh"

usage=$(iostat -n0 -w2 -c2 | awk 'END { print 100 - $3 }')

"$BAR_NAME" -m --set "$NAME" label="${usage}%" label.color="$(level_color "$usage")"
