#!/usr/bin/env bash
set -euo pipefail

echo -ne "\033]0;search-nix-pkgs\007" >/dev/tty

snapshot="$XDG_CACHE_HOME/nixpkgs-snapshot"

sel=$(awk -F'\t' '
		function substr_trim(string, trim_to) {
			if (length(string) > trim_to) {
				return substr(string, 1, trim_to - 1) "…" # only subtract 1 as "..." is a single ligature character
			}
			return string
		}
		{
			printf "%s\t%-30s %-15s %s\n", $1, substr_trim($1, 30), substr_trim($2, 15), $3
		}
	' "$snapshot" |
	fzf --ansi --delimiter='\t' --nth=1 --with-nth=2 --accept-nth=1 --tiebreak=begin \
		--layout=reverse --info=inline \
		--preview='nix eval --raw nixpkgs#{1}.meta.description 2>/dev/null' \
		--preview-window="bottom:3:wrap") || exit 0
printf '%s' "$sel" | wl-copy
