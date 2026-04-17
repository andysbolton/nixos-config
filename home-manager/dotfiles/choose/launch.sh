#!/bin/bash

home_manager_apps="$HOME/Applications/Home Manager Apps"

bookmarks=$(bookmarks.sh &)
apps=$(apps.sh &)

wait

choice=$(
	{
		echo "$apps" |
			xargs -I {} basename {} |
			sort -u
		echo "$bookmarks"
		echo "tickets"
	} | choose -z -m
)

if [ -z "$choice" ]; then
	exit 0
fi

if [[ "$choice" == "tickets" ]]; then
	jira issue list \
		--assignee andy.bolton@smartwyre.com \
		--columns "name,summary,status" \
		--no-headers \
		--plain \
		--status \
		"~done" \
		--raw |
		jq -r '.[] | "\(.key): \(.fields.summary)"' |
		choose |
		awk -F: '{print $1}' |
		pbcopy
	exit 0
fi

# GitHub search
if [[ "$choice" == ?gh* ]]; then
	# Extract everything after "?gh"
	rest=${choice//?gh/}

	# Split into flags and search term at first space
	flags=${rest%% *}      # Flags: everything before first space
	search_term=${rest#* } # Search: everything after first space

	# If no space found, flags equals rest, so reset search_term
	[[ "$flags" == "$rest" ]] && search_term=""

	# Build URL components based on flags
	search_type="code"
	org_filter="org%3ASmartwyre+"
	[[ "$flags" == *"r"* ]] && search_type="repositories"
	[[ "$flags" == *"u"* ]] && org_filter=""

	# Open GitHub search
	open -na "$home_manager_apps/Firefox.app" --args "https://github.com/search?q=$org_filter$search_term&type=$search_type"
	exit 0
fi

# Check if the choice is an app
app=$(echo "$apps" | grep "$choice/$" | head -1)
if [ -n "$app" ]; then
	open -na "$app"
	exit 0
fi

# Check if the choice is a URL
url=$(echo "$choice" | grep -Eo '(http|https)://.*')
if [[ "$url" == http* ]]; then
	open -na "$home_manager_apps/Firefox.app" --args "$url"
	exit 0
fi

echo "Unknown choice: $choice"
