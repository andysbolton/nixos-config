#!/bin/bash

STATE_FILE="/tmp/sketchybar_clock_tz"
tz=$(cat "$STATE_FILE" 2>/dev/null || echo "US/Eastern")

if [ "$SENDER" = "mouse.clicked" ]; then
    [ "$tz" = "US/Eastern" ] && tz="Europe/London" || tz="US/Eastern"
    echo "$tz" >"$STATE_FILE"
fi

sketchybar --set "$NAME" label="$(TZ="$tz" date +"%Y-%m-%d %I:%M:%S %p %Z")"
