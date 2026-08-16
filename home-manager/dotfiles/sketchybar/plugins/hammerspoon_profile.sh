#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

$BAR_NAME --set "$NAME" label="$(hs -c "Profile")" background.border_color="$OVERLAY"
