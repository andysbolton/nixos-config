#!/bin/bash

cache_file="$HOME/.cache/choose_apps.txt"

# Check if cache exists and is recent (less than 1 hour old)
if [ -f "$cache_file" ]; then
	cache_age=$(($(date +%s) - $(stat -f %m "$cache_file")))
	if [ $cache_age -lt 3600 ]; then
		cat "$cache_file"
		exit 0
	fi
fi

# Cache is stale or doesn't exist, regenerate
mkdir -p "$HOME/.cache"

# Generate new output
output=$(fd -t d -d 1 ".app\$" \
	/Users/andybolton/Applications/Home\ Manager\ Apps \
	/Applications \
	/Applications/Utilities/ \
	/System/Applications/ \
	/System/Applications/Utilities/)

# Store in cache
echo "$output" >"$cache_file"

# Output the result
echo "$output"
