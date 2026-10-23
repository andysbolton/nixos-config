#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/stats/level.sh"

used=$(vm_stat | awk -v total="$(sysctl -n hw.memsize)" '
  /page size of/ { page = $8 }
  /Pages active/ { active = $3 }
  /Pages wired down/ { wired = $4 }
  END { printf "%.0f", (active + wired) * page * 100 / total }')

"$BAR_NAME" -m --set "$NAME" label="${used}%" label.color="$(level_color "$used")"
