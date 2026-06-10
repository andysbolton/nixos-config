#!/bin/bash

bar_props=(
  position=top
  height=50
  color="0x00000000"
  display=all
)

"$BAR_NAME" --bar "${bar_props[@]}"

# Left

"$BAR_NAME" --add item power left \
  --set power \
  icon="⏻" \
  label.drawing=off \
  script="$PLUGIN_DIR/power.sh" \
  click_script="\"$BAR_NAME\" --set power popup.drawing=toggle" \
  popup.background.color=$SURFACE \
  popup.background.border_color=$OVERLAY \
  popup.background.border_width=1 \
  popup.background.corner_radius=8 \
  "${default_section[@]}" \
  --subscribe power mouse.exited.global

"$BAR_NAME" --add item power.shutdown popup.power \
  --set power.shutdown icon="⏻" label="Shut Down" width=160 \
  script="$PLUGIN_DIR/power.sh" \
  click_script="osascript -e 'tell app \"System Events\" to shut down'; \"$BAR_NAME\" --set power popup.drawing=off" \
  --subscribe power.shutdown mouse.entered mouse.exited

"$BAR_NAME" --add item power.restart popup.power \
  --set power.restart icon="↻" label="Restart" width=160 \
  script="$PLUGIN_DIR/power.sh" \
  click_script="osascript -e 'tell app \"System Events\" to restart'; \"$BAR_NAME\" --set power popup.drawing=off" \
  --subscribe power.restart mouse.entered mouse.exited

"$BAR_NAME" --add item power.sleep popup.power \
  --set power.sleep icon="⏾" label="Sleep" width=160 \
  script="$PLUGIN_DIR/power.sh" \
  click_script="pmset sleepnow; \"$BAR_NAME\" --set power popup.drawing=off" \
  --subscribe power.sleep mouse.entered mouse.exited

"$BAR_NAME" --add item power.lock popup.power \
  --set power.lock icon="🔐" label="Lock Screen" width=160 \
  script="$PLUGIN_DIR/power.sh" \
  click_script="pmset displaysleepnow; \"$BAR_NAME\" --set power popup.drawing=off" \
  --subscribe power.lock mouse.entered mouse.exited

"$BAR_NAME" --add item power.logout popup.power \
  --set power.logout icon="󰍃" label="Log Out" width=160 \
  script="$PLUGIN_DIR/power.sh" \
  click_script="osascript -e 'tell app \"System Events\" to log out'; \"$BAR_NAME\" --set power popup.drawing=off" \
  --subscribe power.logout mouse.entered mouse.exited

for did in $(yabai -m query --displays 2>/dev/null | jq '.[].index'); do
  local_idx=1
  for sid in $(yabai -m query --spaces --display "$did" | jq '.[].index'); do
    space=(
      space="$sid"
      display="$did"
      icon="$local_idx"
      background.color=0x40ffffff
      background.corner_radius=5
      background.height=25
      label.drawing=off
      script="$PLUGIN_DIR/space.sh"
      click_script="yabai -m space --focus $sid"
    )
    "$BAR_NAME" --add space space."$sid" left --set space."$sid" "${space[@]}"
    local_idx=$((local_idx + 1))
  done
done

for did in $(yabai -m query --displays | jq '.[].index'); do
  "$BAR_NAME" \
    --add item "front_app.$did" left \
    --set "front_app.$did" \
    icon.drawing=off \
    display="$did" \
    script="$PLUGIN_DIR/front_app.sh" \
    "${default_section[@]}" \
    --subscribe "front_app.$did" front_app_switched
done

# Right

"$BAR_NAME" --add item battery right \
  --set battery update_freq=60 script="$PLUGIN_DIR/battery.sh" \
  icon.padding_left=3 \
  icon.padding_right=0 \
  --subscribe battery system_woke power_source_change

"$BAR_NAME" --add item battery.plug right \
  --set battery.plug icon="󰚥" icon.color=$TEXT \
  label.drawing=off \
  icon.padding_right=0 \
  background.drawing=off \
  drawing=off

"$BAR_NAME" --add item spacer.right1 right \
  --set spacer.right1 width=8

"$BAR_NAME" --add item volume right \
  --set volume script="$PLUGIN_DIR/volume.sh" \
  "${default_label[@]}" \
  click_script="$PLUGIN_DIR/mute.sh" \
  --subscribe volume volume_change # "${default_section[@]}" \

slider_props=(
  --set set_volume script="$PLUGIN_DIR/set_volume.sh"
  slider.background.height=6
  slider.background.corner_radius=3
  slider.background.color="$OVERLAY"
  slider.highlight_color="$CYAN"
  slider.knob=⬤
  --subscribe set_volume volume_change mouse.clicked
)

"$BAR_NAME" --add slider set_volume right 150 \
  "${slider_props[@]}"

karabiner_profile=(
  icon="$KEYBOARD"
  update_freq=2
  script="$PLUGIN_DIR/karabiner_profile.sh"
  background.drawing=on
  "${default_section[@]}"
  "${default_label[@]}"
  label.padding_right=8
  icon.padding_left=8
)

"$BAR_NAME" --add item karabiner_profile right \
  --set karabiner_profile "${karabiner_profile[@]}"

# Brackets

"$BAR_NAME" --add bracket volume_group volume set_volume \
  --set volume_group \
  "${default_section[@]}"

"$BAR_NAME" --add bracket battery_group battery battery.plug \
  --set battery_group \
  "${default_section[@]}"
