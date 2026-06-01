#!/bin/bash

cache_file="$HOME/.cache/apps.txt"

# Check if cache exists and is recent (less than 1 hour old)
if [ -f "$cache_file" ]; then
	cache_age=$(($(date +%s) - $(stat -f %m "$cache_file")))
	if [ $cache_age -lt 3600 ]; then
		cat "$cache_file"
		exit 0
	fi
fi

# Generate new output
output=$(
	fd -t d -d 1 ".app\$|.prefPane\$" \
		"$HOME/Applications/Home Manager Apps/" \
		/Applications \
		/Applications/Nix\ Apps \
		/Applications/Utilities/ \
		/System/Applications/ \
		/System/Applications/Utilities/ \
		/System/Library/PreferencePanes/ \
		/System/Library/CoreServices/ \
		/opt/homebrew/Caskroom/ |
		rev |
		sort -r |
		rev
)

# Store in cache
echo "$output" >"$cache_file"

# Output the result
echo "$output"
