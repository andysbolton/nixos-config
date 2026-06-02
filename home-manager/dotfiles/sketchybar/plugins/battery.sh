#!/bin/bash

source "$CONFIG_DIR/colors.sh"

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
    exit 0
fi

case "${PERCENTAGE}" in
9[0-9] | 100)
    ICON=""
    ;;
[6-8][0-9])
    ICON=""
    ;;
[3-5][0-9])
    ICON=""
    ;;
[1-2][0-9])
    ICON=""
    ;;
*) ICON="" ;;
esac

if [ "$PERCENTAGE" -lt 10 ]; then
    COLOR=$RED
elif [ "$PERCENTAGE" -lt 25 ]; then
    COLOR=$ORANGE
elif [ "$PERCENTAGE" -lt 50 ]; then
    COLOR=$YELLOW
else
    COLOR=$GREEN
fi

sketchybar --set "$NAME" \
    icon="$ICON" icon.color="$COLOR" \
    label="${PERCENTAGE}%"

if [ "$CHARGING" != "" ]; then
    sketchybar --set battery.plug drawing=on
else
    sketchybar --set battery.plug drawing=off
fi
