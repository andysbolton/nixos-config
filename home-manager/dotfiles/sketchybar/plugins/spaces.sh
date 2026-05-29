#!/bin/bash

source "$CONFIG_DIR/colors.sh"
PLUGIN_DIR="$CONFIG_DIR/plugins"

# Remove existing space items
sketchybar --remove '/space\..*/' 2>/dev/null

for did in $(yabai -m query --displays 2>/dev/null | jq '.[].index'); do
  local_idx=1
  for sid in $(yabai -m query --spaces --display "$did" | jq '.[].index'); do
    sketchybar --add space space."$sid" left \
      --set space."$sid" \
        space="$sid" \
        icon="$local_idx" \
        icon.padding_left=7 \
        icon.padding_right=7 \
        background.color=0x40ffffff \
        background.corner_radius=5 \
        background.height=25 \
        label.drawing=off \
        script="$PLUGIN_DIR/space.sh" \
        click_script="yabai -m space --focus $sid"
    local_idx=$((local_idx + 1))
  done
done
