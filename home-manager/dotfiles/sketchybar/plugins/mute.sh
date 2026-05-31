#!/bin/bash

if [ "$(osascript -e "output muted of (get volume settings)")" = "true" ]; then
    osascript -e "set volume without output muted"
else
    osascript -e "set volume with output muted"
fi
