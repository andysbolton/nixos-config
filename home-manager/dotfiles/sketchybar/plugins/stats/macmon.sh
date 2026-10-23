#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/stats/level.sh"

macmon pipe -i 2000 |
  jq --unbuffered -r '.gpu_usage[1] * 100 | round' |
  while read -r gpu; do
    "$BAR_NAME" --set gpu label="${gpu}%" label.color="$(level_color "$gpu")"
  done
