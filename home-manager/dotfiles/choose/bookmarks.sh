#!/bin/bash

bookmarks_folder="$HOME/Library/Application Support/Firefox/Profiles/home/"

# copy db since it's locked while firefox is running
csum_orig=$(shasum "${bookmarks_folder}/places.sqlite" | awk '{print $1}')
csum_copy=$(shasum "${bookmarks_folder}/places_copy.sqlite" 2>/dev/null | awk '{print $1}')

if [ "$csum_orig" != "$csum_copy" ]; then
    cp -f "${bookmarks_folder}/places.sqlite" "${bookmarks_folder}/places_copy.sqlite"
fi

sqlite3 -separator ": " \
    "${bookmarks_folder}/places_copy.sqlite" \
    "SELECT b.title, p.url FROM moz_bookmarks b JOIN moz_places p ON b.fk = p.id WHERE b.title IS NOT NULL AND p.url NOT LIKE 'place:%' ORDER BY b.title"
# choose -z |
# grep -Eo '(http|https)://.*' |
# xargs -I {} open -na "$HOME/Applications/Home Manager Apps/Firefox.app" --args {}
