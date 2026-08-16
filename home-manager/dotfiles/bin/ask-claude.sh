#!/usr/bin/env bash
set -euo pipefail

echo -ne "\033]0;ask-claude\007" >/dev/tty

cd "$HOME"

session_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
session_args=(--session-id "$session_id")

while true; do
	read -rep ":) -> " question || exit 0
	[ -z "$question" ] && exit 0
	claude -p "$question" \
		--model haiku \
		--tools WebSearch \
		--allowedTools WebSearch \
		--strict-mcp-config \
		"${session_args[@]}" |
		bat --language md --style plain --paging never
	session_args=(--resume "$session_id")
done
