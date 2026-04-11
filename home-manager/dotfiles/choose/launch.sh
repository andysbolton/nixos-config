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
    } | choose -z -m
)

echo "choice: $choice"

if [ -z "$choice" ]; then
    exit 0
fi

# GitHub search
if [[ "$choice" == ?gh[[:space:]]* ]]; then
    search=${choice//"?gh "/""}
    open -na "$HOME/Applications/Home Manager Apps/Firefox.app" --args "https://github.com/search?q=org%3ASmartwyre+$search&type=code"
    exit 0
fi

# Check if the choice is an app
app=$(echo "$apps" | grep "$choice/$" | head -1)
if [ -n "$app" ]; then
    open -na "$app"
    exit 0
fi

# Check if the choice is a URL
url=$(echo "$choice" | grep -Eo '(http|https)://.*')
if [[ "$url" == http* ]]; then
    open -na "$HOME/Applications/Home Manager Apps/Firefox.app" --args "$url"
    exit 0
fi

echo "Unknown choice: $choice"
