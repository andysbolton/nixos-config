#!/usr/bin/env bash

"$BAR_NAME" -m --set "$NAME" label="$(top -l 2 | grep -E "^CPU" | tail -1 | awk '{ printf "%.2f%%", $3 + $5 }')"
