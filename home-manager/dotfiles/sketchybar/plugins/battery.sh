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

# Same thresholds as waybar's battery states.
if [ "$PERCENTAGE" -le 10 ]; then
    ICON_COLOR=$ERROR LABEL_COLOR=$ERROR
elif [ "$PERCENTAGE" -le 20 ]; then
    ICON_COLOR=$ATTENTION LABEL_COLOR=$ATTENTION
elif [ "$PERCENTAGE" -le 60 ]; then
    ICON_COLOR=$WARN LABEL_COLOR=$WARN
else
    ICON_COLOR=$OK LABEL_COLOR=$FOREGROUND
fi

"$BAR_NAME" --set "$NAME" \
    icon="$ICON" icon.color="$ICON_COLOR" \
    label="$PERCENTAGE%" label.color="$LABEL_COLOR"

if [ "$CHARGING" != "" ]; then
    "$BAR_NAME" --set battery.plug drawing=on
else
    "$BAR_NAME" --set battery.plug drawing=off
fi
