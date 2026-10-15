#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/stats/level.sh"

used=$(df -H | grep -E '^(/dev/disk3s3s1).' | awk '{ printf("%d", $5) }')

"$BAR_NAME" -m --set "$NAME" label="${used}%" label.color="$(level_color "$used")"
