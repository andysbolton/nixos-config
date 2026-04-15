#!/bin/bash

bookmarks_folder="$HOME/Library/Application Support/Firefox/Profiles/home/"
cache_file="$HOME/.cache/choose_bookmarks.txt"

# Check if cache exists and is up to date
if [ -f "$cache_file" ]; then
	# Get checksum of original database
	csum_orig=$(shasum "${bookmarks_folder}/places.sqlite" 2>/dev/null | awk '{print $1}')

	# Get checksum stored with cache
	csum_cached=$(head -n 1 "$cache_file" 2>/dev/null)

	# If checksums match, use cached output
	if [ "$csum_orig" = "$csum_cached" ]; then
		tail -n +2 "$cache_file"
		exit 0
	fi
fi

# Database changed or no cache exists, update cache
mkdir -p "$HOME/.cache"

# Copy DB since it's locked while Firefox is running
csum_orig=$(shasum "${bookmarks_folder}/places.sqlite" | awk '{print $1}')
cp -f "${bookmarks_folder}/places.sqlite" "${bookmarks_folder}/places_copy.sqlite"

# Generate new output
output=$(sqlite3 -separator ": " \
	"${bookmarks_folder}/places_copy.sqlite" \
	"SELECT b.title, p.url FROM moz_bookmarks b JOIN moz_places p ON b.fk = p.id WHERE b.title IS NOT NULL AND p.url NOT LIKE 'place:%' ORDER BY b.title")

# Store checksum + output in cache
echo "$csum_orig" >"$cache_file"
echo "$output" >>"$cache_file"

# Output the result
echo "$output"
