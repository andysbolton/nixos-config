catalog_dir=$(mktemp -d)
trap 'rm -rf "$catalog_dir"' EXIT

bookmarks "$HOME/.mozilla/firefox/home/" >"$catalog_dir/bookmarks" &
nixos-apps >"$catalog_dir/apps" &

wait

bookmarks=$(<"$catalog_dir/bookmarks")
apps=$(<"$catalog_dir/apps")

export bookmarks
export apps
export FZF_DEFAULT_OPTS="--reverse --bind=tab:replace-query"

handle_selection() {
	local result="${1:-$2}"

	[ -z "$result" ] && return

	local choice="${result%% -- *}"
	local args="${result#* -- }"

	[[ "$choice" == "$args" ]] && args=""

	if [[ "$choice" =~ :\ ([^ ]+\.desktop)$ ]]; then
		echo "uwsm app -t service -- ${BASH_REMATCH[1]}"
		return
	fi

	if [[ "$choice" =~ .*(http.*) ]]; then
		url="${BASH_REMATCH[1]}"
		echo "uwsm app -t service -- firefox \"$url\""
		return
	fi

	echo "Unrecognized choice: $choice"
}

options=$(
	{
		echo "$apps"
		echo "$bookmarks"
	}
)

export -f handle_selection
export options

result=$(
	echo "$options" | SHELL="$(command -v bash)" fzf \
		--preview "handle_selection {} {q}" \
		--preview-window="bottom:3:wrap" \
		--preview-label="Action" \
		--prompt "❯ " \
		--bind $'change:first+refresh-preview+reload(echo "$options"; [[ {q} =~ ^[\\?\>] ]] && printf "%s\\n" {q})' \
		--bind "enter:become(handle_selection {} {q})"
)

eval "$result"
