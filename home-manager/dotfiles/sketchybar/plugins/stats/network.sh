#!/usr/bin/env bash

UPDOWN=$(ifstat-legacy -i "en0" -b 0.1 1 | tail -n1)

DOWN_FORMAT=$(echo "$UPDOWN" | awk '{
    print ($1 > 999) ? sprintf("%.2fmb", $1 / 1000) : sprintf("%.2fkb", $1)
}')

UP_FORMAT=$(echo "$UPDOWN" | awk '{
    print ($2 > 999) ? sprintf("%.2fmb", $2 / 1000) : sprintf("%.2fkb", $2)
}')

"$BAR_NAME" --set network.up label="$UP_FORMAT"
"$BAR_NAME" --set network.down label="$DOWN_FORMAT"
