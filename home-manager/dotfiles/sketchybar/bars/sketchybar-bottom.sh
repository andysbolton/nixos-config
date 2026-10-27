#!/bin/bash

# Left

"$BAR_NAME" --bar "${bar[@]}" position=bottom color="#000000"

stat=(
  icon.color="$LABEL"
  icon.font="CaskaydiaCove Nerd Font:Regular:14.0"
  "${icon_with_label[@]}"
  icon.padding_right=10
)

metric=(
  "${stat[@]}"
  icon.font="CaskaydiaCove Nerd Font:Bold:14.0"
  icon.padding_left=0
  label.padding_right=0
)

divider=(
  icon="│"
  icon.color="$DIVIDER"
  icon.font="CaskaydiaCove Nerd Font:Bold:14.0"
  label.drawing=off
  padding_left=0
  padding_right=0
  icon.padding_left="$PAD"
  icon.padding_right="$PAD"
)

add_divider() {
  "$BAR_NAME" --add item "stats.div.$1" left --set "stats.div.$1" "${divider[@]}"
}

"$BAR_NAME" --add item memory left \
  --set memory icon="≡ mem" width=84 update_freq=3 script="$PLUGIN_DIR/stats/ram.sh" \
  "${metric[@]}"

add_divider 1

"$BAR_NAME" --add item cpu left \
  --set cpu icon="▣ cpu" width=84 update_freq=3 script="$PLUGIN_DIR/stats/cpu.sh" \
  "${metric[@]}"

add_divider 2

"$BAR_NAME" --add item disk left \
  --set disk icon="◙ disk" width=93 update_freq=60 script="$PLUGIN_DIR/stats/disk.sh" \
  "${metric[@]}"

add_divider 3

"$BAR_NAME" --add item gpu left \
  --set gpu icon="▤ gpu" width=84 \
  "${metric[@]}"

add_divider 4

"$BAR_NAME" --add item network left \
  --set network icon="≈ net" width=190 update_freq=1 script="$PLUGIN_DIR/stats/network.sh" \
  "${metric[@]}"

pkill -f "macmon pipe"
"$PLUGIN_DIR/stats/macmon.sh" &

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
  icon="♥"
  script="$PLUGIN_DIR/clipboard.sh"
  "${block[@]}"
  "${stat[@]}"
  icon.color="$RED"
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
