#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

IP=$(curl -s --max-time 3 https://ifconfig.me | cut -c 1-20)

if [ -z "$IP" ]; then
  IP="(disconnected)"
fi

if scutil --nc list 2>/dev/null | grep -q "^\* (Connected)" ||
  netstat -rn 2>/dev/null | grep -q "^0/1"; then
  sketchybar --set vpn label="$IP" background.border_color=$TEAL
else
  sketchybar --set vpn label="$IP" background.border_color=$OVERLAY
fi
