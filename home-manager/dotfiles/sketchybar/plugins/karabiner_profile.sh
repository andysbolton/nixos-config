#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

pkill -f 'entr -ns'

echo "$HOME"/.config/karabiner/karabiner.json |
    SHELL="$BASH" entr -ns "
    profile=\$(/opt/homebrew/bin/karabiner_cli --show-current-profile-name)
    $BAR_NAME --set $NAME label=\$profile background.border_color=$OVERLAY
  "
