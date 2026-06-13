#!/usr/bin/env bash

ITEM="clipboard"
LINE="clipboard.line"
LINES_MAX=14
COLS=49
SHORT_MAX=15
PIDFILE="/tmp/sketchybar_clipboard_watch.pid"

render() {
  local full short folded i line
  # An image on the pasteboard has no useful text form; show "(image)".
  if osascript -l JavaScript \
    -e 'ObjC.import("AppKit"); $.NSPasteboard.generalPasteboard.canReadObjectForClassesOptions([$.NSImage], $()) ? "y" : "n"' 2>/dev/null | grep -q y; then
    full="(image)"
  else
    full="$(pbpaste 2>/dev/null | iconv -f UTF-8 -t UTF-8//IGNORE)"
    [ -z "$full" ] && full="(empty)"
  fi

  short=$(printf '%s' "$full")
  [ "${#short}" -gt "$SHORT_MAX" ] && short="${short:0:$SHORT_MAX}…"
  "$BAR_NAME" --set "$ITEM" label="$short"

  # Wrap to $COLS columns, one fixed-width popup item per line.
  folded=$(printf '%s\n' "$full" | fold -s -w "$COLS")
  i=0
  while IFS= read -r line; do
    [ "$i" -ge "$LINES_MAX" ] && break
    [ -z "$line" ] && line=" "
    "$BAR_NAME" --set "$LINE.$i" label="$line" drawing=on
    i=$((i + 1))
  done < <(printf '%s\n' "$folded")
  if [ "$(printf '%s\n' "$folded" | wc -l | tr -d ' ')" -gt "$LINES_MAX" ]; then
    "$BAR_NAME" --set "$LINE.$((LINES_MAX - 1))" label="… (truncated)" drawing=on
  fi
  while [ "$i" -lt "$LINES_MAX" ]; do
    "$BAR_NAME" --set "$LINE.$i" drawing=off
    i=$((i + 1))
  done
}

case "$SENDER" in
mouse.entered)
  "$BAR_NAME" --set "$ITEM" popup.drawing=on
  exit 0
  ;;
mouse.exited | mouse.exited.global)
  "$BAR_NAME" --set "$ITEM" popup.drawing=off
  exit 0
  ;;
esac

# Repaint now: on a reload the items are recreated blank, and an
# already-running loop won't repaint until the clipboard next changes.
render

# If the watch loop is already running, nothing more to do.
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
  exit 0
fi

# Otherwise start it, backgrounded so it outlives this (reaped) script.
{
  last=""
  while true; do
    # macOS has no clipboard-change event, so poll the cheap pasteboard
    # changeCount and only repaint when it actually changes.
    count=$(osascript -l JavaScript \
      -e 'ObjC.import("AppKit"); $.NSPasteboard.generalPasteboard.changeCount' 2>/dev/null)
    if [ -n "$count" ] && [ "$count" != "$last" ]; then
      last="$count"
      render
    fi
    sleep 0.3
  done
} &

echo $! >"$PIDFILE"
