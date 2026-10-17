#!/usr/bin/env bash
# env vars sidestep AppleScript string escaping
MSG="$msg" TITLE="$title" /usr/bin/osascript -e \
  'display notification (system attribute "MSG") with title (system attribute "TITLE") sound name "Glass"'

# Mark the session's space in the bar; space.sh un-marks it on
# focus. The nearest ancestor owning a yabai window is the
# session's terminal process — but WezTerm is one process for
# every window, so prefer the window titled like this pane's
# OS window. PATH wezterm, not nix-pinned: the cli must
# version-match the running GUI.
command -v yabai >/dev/null && command -v sketchybar >/dev/null || exit 0
windows=$(yabai -m query --windows)
wt=""
[ -n "${WEZTERM_PANE:-}" ] && command -v wezterm >/dev/null && \
  wt=$(wezterm cli list --format json 2>/dev/null | jq -r --argjson p "$WEZTERM_PANE" \
    '[.[] | select(.pane_id == $p) | .window_title] | first // empty' || true)
pid=$$ space=""
while [ "$pid" -gt 1 ] 2>/dev/null; do
  space=$(jq -r --argjson pid "$pid" --arg t "$wt" \
    '[.[] | select(.pid == $pid)] | ([.[] | select(.title == $t)] + .) | (first | .space) // empty' <<<"$windows")
  [ -z "$space" ] || break
  pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
done
# skip spaces visible on any display; space.sh clears those on
# the next space event anyway
if [ -n "$space" ] && ! yabai -m query --spaces | jq -e --argjson s "$space" \
    'any(.[]; ."is-visible" and .index == $s)' >/dev/null; then
  sketchybar --set "space.$space" icon.highlight=on 2>/dev/null || true
fi
