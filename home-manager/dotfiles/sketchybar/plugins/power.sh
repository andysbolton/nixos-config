#!/bin/bash

source "$CONFIG_DIR/colors.sh"

case "$SENDER" in
  mouse.exited.global)
    sketchybar --set power popup.drawing=off
    ;;
  mouse.entered)
    sketchybar --set "$NAME" background.color=$OVERLAY background.corner_radius=6 background.drawing=on
    ;;
  mouse.exited)
    sketchybar --set "$NAME" background.drawing=off
    ;;
esac
