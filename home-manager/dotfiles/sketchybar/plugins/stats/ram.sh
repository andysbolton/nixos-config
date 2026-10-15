#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/stats/level.sh"

used=$(memory_pressure | grep "System-wide memory free percentage:" | awk '{ printf("%02.0f", 100 - $5) }')

"$BAR_NAME" -m --set "$NAME" label="${used}%" label.color="$(level_color "$used")"
