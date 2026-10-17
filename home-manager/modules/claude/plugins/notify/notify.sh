#!/usr/bin/env bash
input=$(cat)
sid=$(jq -r .session_id <<<"$input")
cwd=$(jq -r .cwd <<<"$input")
msg=$(jq -r '.message // "Needs your attention"' <<<"$input")
# Session name via the live-session registry (undocumented internals);
# fall back to the project directory name.
name=$(jq -rs --arg sid "$sid" \
  '[.[] | select(.sessionId == $sid) | .name] | first // empty' \
  "$HOME"/.claude/sessions/*.json 2>/dev/null || true)
title="Claude Code - ${name:-${cwd##*/}}"

