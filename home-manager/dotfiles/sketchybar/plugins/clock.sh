#!/bin/bash

STATE_FILE="/tmp/sketchybar_clock_tz"
tz=$(cat "$STATE_FILE" 2>/dev/null || echo "US/Eastern")

if [ "$SENDER" = "mouse.clicked" ]; then
    [ "$tz" = "US/Eastern" ] && tz="Europe/London" || tz="US/Eastern"
    echo "$tz" >"$STATE_FILE"
fi

DATE_TIME=$(TZ="$tz" date +"%Y-%m-%d %I:%M:%S %p %Z")

"$BAR_NAME" --set "clock.date" label="$(echo "$DATE_TIME" | cut -d ' ' -f 1)"
"$BAR_NAME" --set "clock.time" label="$(echo "$DATE_TIME" | cut -d ' ' -f 2-4)"
