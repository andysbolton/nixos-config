#!/bin/bash

"$BAR_NAME" --bar "${bar[@]}" position=top color="$TRANSPARENT"

# Left

power=(
  icon="⏻"
  "${icon_only[@]}"
  "${block[@]}"
  script="$PLUGIN_DIR/power.sh"
  click_script="\"$BAR_NAME\" --set power popup.drawing=toggle"
  popup.background.color="$SURFACE"
  popup.background.border_color="$OVERLAY"
  popup.background.border_width=1
  popup.background.corner_radius=8
)

"$BAR_NAME" --add item power left \
  --set power "${power[@]}" \
  --subscribe power mouse.exited.global

power_menu_item() {
  local name=$1 icon=$2 label=$3 cmd=$4
  "$BAR_NAME" --add item "power.$name" popup.power \
    --set "power.$name" icon="$icon" label="$label" width=160 \
    script="$PLUGIN_DIR/power.sh" \
    click_script="$cmd; \"$BAR_NAME\" --set power popup.drawing=off" \
    --subscribe "power.$name" mouse.entered mouse.exited
}

power_menu_item shutdown "⏻" "Shut Down" "osascript -e 'tell app \"System Events\" to shut down'"
power_menu_item restart "↻" "Restart" "osascript -e 'tell app \"System Events\" to restart'"
power_menu_item sleep "⏾" "Sleep" "pmset sleepnow"
power_menu_item lock "🔐" "Lock Screen" "pmset displaysleepnow"
power_menu_item logout "󰍃" "Log Out" "osascript -e 'tell app \"System Events\" to log out'"

for did in $(yabai -m query --displays 2>/dev/null | jq '.[].index'); do
  local_idx=1
  for sid in $(yabai -m query --spaces --display "$did" | jq '.[].index'); do
    space=(
      space="$sid"
      display="$did"
      icon="$local_idx"
      "${icon_only[@]}"
      background.color="$HIGHLIGHT"
      background.corner_radius=5
      script="$PLUGIN_DIR/space.sh"
      click_script="yabai -m space --focus $sid"
    )
    "$BAR_NAME" --add space space."$sid" left --set space."$sid" "${space[@]}"
    local_idx=$((local_idx + 1))
  done
done

for did in $(yabai -m query --displays | jq '.[].index'); do
  front_app=(
    display="$did"
    "${label_only[@]}"
    "${block[@]}"
    script="$PLUGIN_DIR/front_app.sh"
  )
  "$BAR_NAME" --add item "front_app.$did" left \
    --set "front_app.$did" "${front_app[@]}" \
    --subscribe "front_app.$did" front_app_switched
done

# Right

battery=(
  update_freq=60
  script="$PLUGIN_DIR/battery.sh"
  "${icon_with_label[@]}"
  icon.padding_right=0
  icon.padding_left=0
  label.padding_right=0
  background.padding_left=0
)

"$BAR_NAME" --add item battery right \
  --set battery "${battery[@]}" \
  --subscribe battery system_woke power_source_change

battery_plug=(
  icon="󰚥"
  label.drawing=off
  icon.padding_right=0
  icon.padding_left=0
)

"$BAR_NAME" --add item battery.plug right \
  --set battery.plug "${battery_plug[@]}"

"$BAR_NAME" --add bracket battery_group battery battery.plug \
  --set battery_group "${block[@]}"

"$BAR_NAME" --add item battery_spacer right \
  --set battery_spacer width="$GAP" background.drawing=off \
  icon.drawing=off label.drawing=off

microphone=(
  icon="$MIC"
  script="$PLUGIN_DIR/microphone.sh"
  update_freq=5
  "${block[@]}"
  "${icon_only[@]}"
)

"$BAR_NAME" --add item microphone right \
  --set microphone "${microphone[@]}" \
  --subscribe microphone mouse.clicked

"$BAR_NAME" --add item microphone_spacer right \
  --set microphone_spacer width="$GAP" background.drawing=off \
  icon.drawing=off label.drawing=off

volume=(
  script="$PLUGIN_DIR/volume.sh"
  click_script="$PLUGIN_DIR/mute.sh"
  icon.padding_left="$PAD"
)

"$BAR_NAME" --add item volume right \
  --set volume "${volume[@]}" \
  "${icon_with_label[@]}" \
  --subscribe volume volume_change

set_volume=(
  script="$PLUGIN_DIR/set_volume.sh"
  background.padding_left=0
  background.padding_right=0
  slider.background.height=6
  slider.background.corner_radius=3
  slider.background.color="$OVERLAY"
  slider.highlight_color="$CYAN"
  slider.knob=⬤
)

"$BAR_NAME" --add slider set_volume right 180 \
  --set set_volume "${set_volume[@]}" \
  "${icon_with_label[@]}" \
  --subscribe set_volume volume_change mouse.clicked

"$BAR_NAME" --add bracket volume_group volume set_volume \
  --set volume_group "${block[@]}"

"$BAR_NAME" --add item volume_spacer right \
  --set volume_spacer width="$GAP" background.drawing=off \
  icon.drawing=off label.drawing=off

karabiner_profile=(
  icon="$KEYBOARD"
  script="$PLUGIN_DIR/karabiner_profile.sh"
  "${block[@]}"
  "${icon_with_label[@]}"
  background.padding_right=0
)

"$BAR_NAME" --add item karabiner_profile right \
  --set karabiner_profile "${karabiner_profile[@]}"
