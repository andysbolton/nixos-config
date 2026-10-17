#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

PROFILE=$(hs -c "Profile")

case "$PROFILE" in
linux) COLOR="$ATTENTION" ;;
*) COLOR="$UNFOCUSED" ;;
esac

$BAR_NAME --set "$NAME" label="$PROFILE" icon.color="$COLOR" label.color="$COLOR" background.border_color="$COMMENT"
