bookmarks=$(bookmarks "$HOME/.mozilla/firefox/home/" &)

wait

export bookmarks
export FZF_DEFAULT_OPTS="--reverse --bind=tab:replace-query"

handle_selection() {
	local result="${1:-$2}"

	[ -z "$result" ] && return

	local choice="${result%% -- *}"
	local args="${result#* -- }"

	[[ "$choice" == "$args" ]] && args=""

	if [[ "$choice" =~ .*(http.*) ]]; then
		url="${BASH_REMATCH[1]}"
		open_app "Firefox.app" "\"$url\"" -na
		return
	fi

	echo "Unrecognized choice: $choice"
}

options=$(
	{
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
