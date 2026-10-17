#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# The $SELECTED variable is available for space components and indicates if
# the space invoking this script (with name: $NAME) is currently selected:
# https://felixkratz.github.io/SketchyBar/config/components#space----associate-mission-control-spaces-with-an-item

color="$FOREGROUND"
yabai -m query --windows --space "${NAME#space.}" |
  jq -e 'any(.[]; .title | test("^[✳◐◑◒◓] "))' >/dev/null && color="$GREEN"

args=(background.drawing="$SELECTED" icon.color="$color")
# focusing a space dismisses any claude-attention mark on it
[ "$SELECTED" = "true" ] && args+=(icon.highlight=off)

"$BAR_NAME" --set "$NAME" "${args[@]}"
