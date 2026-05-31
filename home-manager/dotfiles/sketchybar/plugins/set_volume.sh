#!/bin/bash

if [ "$SENDER" = "volume_change" ]; then
    VOLUME="$INFO"

    sketchybar --set "$NAME" icon="$ICON" slider.percentage="$VOLUME"
fi

if [ "$SENDER" = "mouse.clicked" ]; then
    osascript -e "set volume output volume $PERCENTAGE"
fi
