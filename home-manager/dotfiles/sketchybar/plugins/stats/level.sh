#!/usr/bin/env bash

# Label colour for a load percentage; same thresholds as waybar's loadStates.
level_color() {
  if [ "$1" -ge 95 ]; then
    echo "$ERROR"
  elif [ "$1" -ge 85 ]; then
    echo "$ATTENTION"
  elif [ "$1" -ge 70 ]; then
    echo "$WARN"
  else
    echo "$FOREGROUND"
  fi
}
