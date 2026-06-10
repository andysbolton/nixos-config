#!/bin/bash

source "$CONFIG_DIR/colors.sh"

case "$SENDER" in
  mouse.exited.global)
    "$BAR_NAME" --set power popup.drawing=off
    ;;
  mouse.entered)
    "$BAR_NAME" --set "$NAME" background.color=$OVERLAY background.corner_radius=6 background.drawing=on
    ;;
  mouse.exited)
    "$BAR_NAME" --set "$NAME" background.drawing=off
    ;;
esac
