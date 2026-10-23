#!/bin/bash

# Left

"$BAR_NAME" --bar "${bar[@]}" position=bottom color="#000000"

stat=(
  icon.color="$BLUE"
  icon.font="CaskaydiaCove Nerd Font:Regular:14.0"
  "${icon_with_label[@]}"
  icon.padding_right=10
)

"$BAR_NAME" --add item network left \
  --set network icon="[net]" width=190 update_freq=1 script="$PLUGIN_DIR/stats/network.sh" \
  "${stat[@]}"

"$BAR_NAME" --add item disk left \
  --set disk icon="[disk]" width=94 update_freq=60 script="$PLUGIN_DIR/stats/disk.sh" \
  "${stat[@]}"

"$BAR_NAME" --add item memory left \
  --set memory icon="[mem]" width=86 update_freq=3 script="$PLUGIN_DIR/stats/ram.sh" \
  "${stat[@]}"

"$BAR_NAME" --add item cpu left \
  --set cpu icon="[cpu]" width=86 update_freq=3 script="$PLUGIN_DIR/stats/cpu.sh" \
  "${stat[@]}"

"$BAR_NAME" --add item gpu left \
  --set gpu icon="[gpu]" width=86 \
  "${stat[@]}"

pkill -f "macmon pipe"
"$PLUGIN_DIR/stats/macmon.sh" &

"$BAR_NAME" --add bracket stats network disk memory cpu gpu \
  --set stats "${block[@]}"

# Center

clock_props=(
  icon.drawing=off
  label.padding_left=0
  label.padding_right=0
  padding_left=3
  padding_right=3
  script="$PLUGIN_DIR/clock.sh"
)

"$BAR_NAME" --add item clock.date center \
  --set clock.date "${clock_props[@]}" \
  label.color="$DARK_FOREGROUND" \
  update_freq=1 \
  --subscribe clock.date mouse.clicked

"$BAR_NAME" --add item clock.time center \
  --set clock.time "${clock_props[@]}" \
  update_freq=0 \
  --subscribe clock.time mouse.clicked

# Right

vpn=(
  icon="[ip]"
  update_freq=10
  script="$PLUGIN_DIR/stats/vpn.sh"
  "${block[@]}"
  "${stat[@]}"
)

"$BAR_NAME" --add item vpn right \
  --set vpn "${vpn[@]}"

clipboard=(
  icon="[s]"
  script="$PLUGIN_DIR/clipboard.sh"
  "${block[@]}"
  "${stat[@]}"
  popup.background.color="$LIGHTER_BACKGROUND"
  popup.background.border_color="$COMMENT"
  popup.background.border_width=1
  popup.background.corner_radius=8
  popup.align=right
  popup.height=22
)

"$BAR_NAME" --add item clipboard right \
  --set clipboard "${clipboard[@]}" \
  --subscribe clipboard mouse.entered mouse.exited

for i in $(seq 0 13); do
  "$BAR_NAME" --add item clipboard.line."$i" popup.clipboard
  "$BAR_NAME" --set clipboard.line."$i" drawing=off width=440 align=left \
    label.font="CaskaydiaCove Nerd Font:Regular:13.0" \
    label.padding_left="$GAP" label.padding_right="$GAP"
done
