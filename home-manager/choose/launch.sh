#!/bin/bash

base_dir="$(dirname "$0")"

bookmarks=$("${base_dir}/bookmarks.sh" &)

apps=$("${base_dir}/apps.sh" &)

wait

choice=$(
    {
        echo "$apps" |
            xargs -I {} basename {} |
            sort -u
        echo "$bookmarks"
    } | choose -z
)

app=$(echo "$apps" | grep "$choice/$" | head -1)
if [ -n "$app" ]; then
    open -na "$app"
    exit 1
fi

url=$(echo "$choice" | grep -Eo '(http|https)://.*')
if [[ "$url" == http* ]]; then
    open -na "$HOME/Applications/Home Manager Apps/Firefox.app" --args "$url"
    exit 1
fi

echo "Unknown choice: $choice"
