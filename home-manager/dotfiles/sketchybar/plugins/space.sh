#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# The $SELECTED variable is available for space components and indicates if
# the space invoking this script (with name: $NAME) is currently selected:
# https://felixkratz.github.io/SketchyBar/config/components#space----associate-mission-control-spaces-with-an-item

"$BAR_NAME" --set "$NAME" background.drawing="$SELECTED"

# focusing a space dismisses any claude-attention mark on it
[ "$SELECTED" = "true" ] && "$BAR_NAME" --set "$NAME" icon.color="$TEXT"
