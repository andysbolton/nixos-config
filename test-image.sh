#!/usr/bin/env bash

wl-paste --type image/png >/tmp/lan-mouse-clip.png

wl-paste --type image/png |
  ssh -o BatchMode=yes -o ConnectTimeout=3 work 'sh -c "f=\$(mktemp /tmp/lan-mouse-clip.XXXXXX); cat > \"\$f\"; osascript -e \"set the clipboard to (read (POSIX file \"\$f\") as «class PNGf»)\"; echo \"\$f\""'

# wl-paste --type image/png |
#   ssh -o BatchMode=yes -o ConnectTimeout=3 work 'sh -c "f=\$(mktemp /tmp/lan-mouse-clip.XXXXXX); cat > \"\$f\"; osascript -e \"set the clipboard to (read (POSIX file \"\$f\") as «class PNGf»)\" >/dev/null 2>&1; echo \"\$\"; rm -f \"\$f\""'
