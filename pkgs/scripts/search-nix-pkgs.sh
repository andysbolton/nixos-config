set -euo pipefail

snapshot="$XDG_CACHE_HOME/nixpkgs-snapshot"

sel=$(cat "$snapshot" |
	fzf --ansi --nth=1 --accept-nth=1 \
		--layout=reverse --info=inline \
		--preview='nix eval --raw nixpkgs#{1}.meta.description 2>/dev/null' \
		--preview-window="bottom:3:wrap") || exit 0
printf '%s' "$sel" | (wl-copy || pbcopy)
