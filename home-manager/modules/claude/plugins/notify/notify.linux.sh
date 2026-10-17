#!/usr/bin/env bash
notify-send "$title" "$msg"
canberra-gtk-play -f "$NOTIFY_SOUND"
