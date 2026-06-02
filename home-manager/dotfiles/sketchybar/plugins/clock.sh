#!/bin/bash

STATE_FILE="/tmp/sketchybar_clock_tz"
tz=$(cat "$STATE_FILE" 2>/dev/null || echo "America/Denver")

if [ "$SENDER" = "mouse.clicked" ]; then
    [ "$tz" = "America/Denver" ] && tz="Europe/London" || tz="America/Denver"
    echo "$tz" > "$STATE_FILE"
fi

sketchybar --set "$NAME" label="$(TZ="$tz" date +"%Y-%m-%d %I:%M:%S %p %Z")"
