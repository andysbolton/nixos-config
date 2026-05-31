#!/bin/bash

cache_file="$HOME/.cache/azure-resource-types.txt"

# Check if cache exists and is recent (less than 3 days old)
if [ -f "$cache_file" ]; then
	cache_age=$(($(date +%s) - $(stat -f %m "$cache_file")))
	if [ $cache_age -lt 259200 ]; then
		cat "$cache_file"
		exit 0
	fi
fi

output=$(
	az graph query -q "resources | project type | union (resourcecontainers | project type) | distinct type" --query "data[].type" |
		jq -r '.[] | "az.\(. | split("/")[-1]): https://portal.azure.com/#browse/\(. | @uri)"'
)

# Store in cache
echo "$output" >"$cache_file"

# Output the result
echo "$output"
