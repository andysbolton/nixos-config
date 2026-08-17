#!/bin/bash

STATE_FILE="/tmp/sketchybar_clock_tz"
tz=$(cat "$STATE_FILE" 2>/dev/null || echo "America/Denver")
# tz=$(cat "$STATE_FILE" 2>/dev/null || echo "America/Denver")

if [ "$SENDER" = "mouse.clicked" ]; then
    [ "$tz" = "America/Denver" ] && tz="Europe/London" || tz="America/Denver"
    echo "$tz" >"$STATE_FILE"
fi

DATE_TIME=$(TZ="$tz" date +"%Y-%m-%d %I:%M:%S %p %Z")

"$BAR_NAME" --set "clock.date" label="$(echo "$DATE_TIME" | cut -d ' ' -f 1)"
"$BAR_NAME" --set "clock.time" label="$(echo "$DATE_TIME" | cut -d ' ' -f 2-4)"
