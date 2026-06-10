#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

profile=$(karabiner_cli --show-current-profile-name)

if [ $(launchctl list | grep -i karabiner | wc -l) -ne 5 ]; then
  sketchybar --set "$NAME" label="(error)" background.border_color="$RED"
elif [ "$profile" = "Empty" ]; then
  sketchybar --set "$NAME" label="$profile" background.border_color="$YELLOW"
else
  sketchybar --set "$NAME" label="$profile" background.border_color="$OVERLAY"
fi
