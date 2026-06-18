#!/usr/bin/env bash
set -euo pipefail

snapshot="$XDG_CACHE_HOME/nixpkgs-snapshot"

sel=$(awk -F'\t' '
		function substr_trim(string, trim_to) {
			if (length(string) > trim_to) {
				return substr(string, 1, trim_to - 3) "…"
			}
			return string
		}
		{
			printf "%s\t%-30s %-15s %s\n", $1, substr_trim($1, 30), substr_trim($2, 15), $3
		}
	' "$snapshot" |
	fzf --ansi --delimiter='\t' --nth=1 --with-nth=2 --accept-nth=1 --tiebreak=begin \
		--layout=reverse --border --margin=1 --padding=1 --info=inline \
		--preview='nix eval --raw nixpkgs#{1}.meta.description 2>/dev/null' \
		--preview-window='bottom:20%') || exit 0
printf '%s' "$sel" | wl-copy
