#!/usr/bin/env bash

UPDOWN=$(ifstat-legacy -i "en0" -b 0.1 1 | tail -n1)
DOWN=$(echo "$UPDOWN" | awk "{ print \$1 }" | cut -f1 -d ".")
UP=$(echo "$UPDOWN" | awk "{ print \$2 }" | cut -f1 -d ".")

if [ "$DOWN" -gt "999" ]; then
    DOWN_FORMAT=$(echo "$DOWN" | awk '{ printf "%03.0fmb", $1 / 1000}')
else
    DOWN_FORMAT=$(echo "$DOWN" | awk '{ printf "%03.0fkb", $1}')
fi

if [ "$UP" -gt "999" ]; then
    UP_FORMAT=$(echo "$UP" | awk '{ printf "%03.0fmb", $1 / 1000}')
else
    UP_FORMAT=$(echo "$UP" | awk '{ printf "%03.0fkb", $1}')
fi

sketchybar --set network label="↑ ${UP_FORMAT} ↓ ${DOWN_FORMAT}"
