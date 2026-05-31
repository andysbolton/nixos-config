#!/bin/bash

# Change title so yabai can track
echo -ne "\033]0;launch.sh\007" >/dev/tty

bookmarks=$(bookmarks.sh &)
apps=$(apps.sh &)
azure_resource_types=$(azure-resource-types.sh &)

wait

export bookmarks
export apps
export azure_resource_types
export FZF_DEFAULT_OPTS="--reverse --bind=tab:replace-query"

open_app() {
	local app="$1"
	local args="$2"
	shift 2
	local cmd="open"
	[[ -n "$*" ]] && cmd+=" $*"
	cmd+=" \"$app\""
	[[ -n "$args" ]] && cmd+=" --args $args"
	echo "$cmd"
}

handle_selection() {
	local result="${1:-$2}"

	[ -z "$result" ] && return

	local choice="${result%% -- *}"
	local args="${result#* -- }"

	[[ "$choice" == "$args" ]] && args=""

	if [[ "$choice" == "tickets" ]]; then
		cat <<-'EOF'
			jira issue list --assignee andy.bolton@smartwyre.com --columns "name,summary,status" --no-headers --plain --status "~done" --raw |
			jq -r 'map("(\(.fields.status.name)) \(.key): \(.fields.summary)") | sort_by(.) | .[]' |
			fzf | sed -E 's/^\(.+\) (.+-[0-9]+):.+/\1/' | tr -d '\n' | pbcopy
		EOF
		return

	elif [[ "$choice" == "spaces" ]]; then
		echo "spaces.sh"
		return

	elif [[ "$choice" =~ ^\?gh ]]; then
		# Extract everything after "?gh"
		rest=${choice//?gh/}

		# Split into flags and search term at first space
		flags=${rest%% *} #everything before first space
		search=${rest#* } # everything after first space

		type="code"
		org_filter="org%3ASmartwyre+"

		[[ "$flags" == *"r"* ]] && type="repositories"
		[[ "$flags" == *"u"* ]] && org_filter=""

		open_app "Firefox.app" "\"https://github.com/search?q=$org_filter$search&type=$type\"" -na
		return

	elif app_match=$(echo "$apps" | grep "$choice/" | head -1) && [ -n "$app_match" ]; then
		if [[ "$app_match" == *.app/* ]]; then
			open_app "$choice" "$args" -na
			return
		elif [[ "$app_match" == *.prefPane/ ]]; then
			open_app "$app_match" "$args"
			return
		fi

	elif [[ "$choice" =~ .*(http.*) ]]; then
		url="${BASH_REMATCH[1]}"
		open_app "Firefox.app" "\"$url\"" -na
		return

	elif [[ "$choice" =~ ^\>\ (.*) ]]; then
		cmd="${BASH_REMATCH[1]}"

		if [[ "$cmd" =~ ^[[:space:]]*$ ]]; then
			echo "Can't run an empty command." >&2
			return
		fi

		open_app "WezTerm" "start --always-new-process -- fish -l -C '$cmd'" -na
		return
	fi

	echo "Unrecognized choice: $choice"
}

options=$(
	{
		echo "$apps" |
			xargs -I {} basename {} |
			sort -u
		echo "$bookmarks"
		echo "$azure_resource_types"
		echo "tickets"
		echo "spaces"
	}
)

export -f open_app
export -f handle_selection
export options

result=$(
	echo "$options" | SHELL=/bin/bash fzf \
		--preview "handle_selection {} {q}" \
		--preview-window="bottom:3:wrap" \
		--preview-label="Action" \
		--prompt "❯ " \
		--bind $'change:first+refresh-preview+reload(echo "$options"; [[ {q} =~ ^[\\?\>] ]] && printf "%s\\n" {q})' \
		--bind "enter:become(handle_selection {} {q})"
)

eval "$result"
