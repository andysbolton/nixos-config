#!/usr/bin/env bash

"$BAR_NAME" -m --set "$NAME" label="$(df -H | grep -E '^(/dev/disk3s3s1).' | awk '{ printf ("%s\n", $5) }')"
