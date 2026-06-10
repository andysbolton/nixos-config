#!/bin/bash

bar_props=(
  position=bottom
  height=50
  color="$BASE"
  display=all
)

"$BAR_NAME" --bar "${bar_props[@]}"

# Left

"$BAR_NAME" --add item network.up left \
  --set network.up \
  script="$PLUGIN_DIR/stats/network.sh" \
  label.width=75 \
  update_freq=1 \
  "${default_label[@]}"

"$BAR_NAME" --add item network.down left \
  --set network.down \
  label.width=75 \
  "${default_label[@]}"

disk=(
  icon="$DISK"
  update_freq=60
  script="$PLUGIN_DIR/stats/disk.sh"
  "${default_label[@]}"
)

"$BAR_NAME" --add item disk left \
  --set disk "${disk[@]}"

memory=(
  icon="$MEMORY"
  update_freq=5
  label.width=25
  script="$PLUGIN_DIR/stats/ram.sh"
  "${default_label[@]}"
)

"$BAR_NAME" --add item memory left \
  --set memory "${memory[@]}"

cpu=(
  icon="$CPU"
  update_freq=3
  script="$PLUGIN_DIR/stats/cpu.sh"
  label.width=60
  "${default_label[@]}"
)

"$BAR_NAME" --add item cpu left \
  --set cpu "${cpu[@]}"

"$BAR_NAME" --add bracket stats cpu memory disk network.up network.down \
  --set stats \
  "${default_section[@]}" \
  background.drawing=on

# Center

clock_props=(
  update_freq=1
  icon.drawing=off
  background.drawing=on
  label.padding_left=0
  label.padding_right=0
)

"$BAR_NAME" --add item "clock.date" center \
  --set "clock.date" "${clock_props[@]}" display="1" script="$PLUGIN_DIR/clock.sh" label.color="$SUBTEXT" \
  --subscribe "clock.date" mouse.clicked \
  --add item "clock.time" center \
  --set "clock.time" "${clock_props[@]}" display="1" \
  --subscribe "clock.time" mouse.clicked

# Right

vpn=(
  icon="$NETWORK"
  update_freq=10
  script="$PLUGIN_DIR/stats/vpn.sh"
  "${default_section[@]}"
  "${default_label[@]}"
  icon.padding_left=9
  text.padding_right=9
)

"$BAR_NAME" --add item vpn right \
  --set vpn "${vpn[@]}"
