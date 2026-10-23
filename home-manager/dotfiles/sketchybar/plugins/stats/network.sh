#!/usr/bin/env bash

UPDOWN=$(ifstat-legacy -i "en0" 0.1 1 | tail -n1)

LABEL=$(echo "$UPDOWN" | awk '
  function rate(kib,    b, i, units) {
    split(",k,M,G", units, ",")
    b = kib * 1024
    for (i = 1; b >= 1000 && i < 4; i++) b /= 1000
    return sprintf("%.1f%sB", b, units[i])
  }
  { printf "↑%s ↓%s", rate($2), rate($1) }')

"$BAR_NAME" --set network label="$LABEL"
