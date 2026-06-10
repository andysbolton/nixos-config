#!/usr/bin/env bash

UPDOWN=$(ifstat-legacy -i "en0" -b 0.1 1 | tail -n1)

DOWN_FORMAT=$(echo "$UPDOWN" | awk '{
    print ($1 > 999) ? sprintf("%07.3fmb", $1 / 1000) : sprintf("%07.3fmb", $1)
}')

UP_FORMAT=$(echo "$UPDOWN" | awk '{
    print ($2 > 999) ? sprintf("%07.3fmb", $2 / 1000) : sprintf("%07.3fkb", $2)
}')

"$BAR_NAME" --set network.up icon="↑" label="$UP_FORMAT"
"$BAR_NAME" --set network.down icon="↓" label="$DOWN_FORMAT"
