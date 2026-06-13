#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

# macOS exposes no "input muted" flag over AppleScript, so on/off is just input
# volume non-zero vs zero.
input_volume() {
  osascript -e "input volume of (get volume settings)" 2>/dev/null
}

mic_on() {
  local v
  v=$(input_volume)
  [[ "$v" =~ ^[0-9]+$ ]] && [ "$v" -gt 0 ]
}

if [ "$SENDER" = "mouse.clicked" ]; then
  if mic_on; then
    osascript -e "set volume input volume 0"
  else
    osascript -e "set volume input volume 100"
  fi
fi

if mic_on; then
  "$BAR_NAME" --set "$NAME" icon="$MIC" icon.color="$GREEN"
else
  "$BAR_NAME" --set "$NAME" icon="$MIC_OFF" icon.color="$RED"
fi
