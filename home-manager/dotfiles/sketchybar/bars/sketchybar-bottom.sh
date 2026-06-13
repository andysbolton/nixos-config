#!/bin/bash

# Left

"$BAR_NAME" --bar "${bar[@]}" position=bottom color="#000000"

"$BAR_NAME" --add item network.up left \
  --set network.up icon="↑" width=95 update_freq=1 script="$PLUGIN_DIR/stats/network.sh" \
  "${icon_with_label[@]}"

"$BAR_NAME" --add item network.down left \
  --set network.down icon="↓" width=95 \
  "${icon_with_label[@]}"

"$BAR_NAME" --add item disk left \
  --set disk icon="$DISK" width=58 update_freq=60 script="$PLUGIN_DIR/stats/disk.sh" \
  "${icon_with_label[@]}"

"$BAR_NAME" --add item memory left \
  --set memory icon="$MEMORY" width=58 update_freq=3 script="$PLUGIN_DIR/stats/ram.sh" \
  "${icon_with_label[@]}"

"$BAR_NAME" --add item cpu left \
  --set cpu icon="$CPU" width=76 update_freq=3 script="$PLUGIN_DIR/stats/cpu.sh" \
  "${icon_with_label[@]}"

"$BAR_NAME" --add bracket stats network.up network.down disk memory cpu \
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
  label.color="$SUBTEXT" \
  update_freq=1 \
  --subscribe clock.date mouse.clicked

"$BAR_NAME" --add item clock.time center \
  --set clock.time "${clock_props[@]}" \
  frequency=0 \
  --subscribe clock.time mouse.clicked

# Right

vpn=(
  icon="$NETWORK"
  update_freq=10
  script="$PLUGIN_DIR/stats/vpn.sh"
  icon.padding_right="$PAD"
  "${block[@]}"
  "${icon_with_label[@]}"
)

"$BAR_NAME" --add item vpn right \
  --set vpn "${vpn[@]}"

# "$BAR_NAME" --add item clipboard_spacer right \
#   --set clipboard_spacer width="$GAP" background.drawing=off \
#   icon.drawing=off label.drawing=off

clipboard=(
  icon="$CLIPBOARD"
  script="$PLUGIN_DIR/clipboard.sh"
  "${block[@]}"
  "${icon_with_label[@]}"
  popup.background.color="$SURFACE"
  popup.background.border_color="$OVERLAY"
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
