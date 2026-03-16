#!/usr/bin/env bash

query="$(
    printf '' | rofi -dmenu -p 'Search package:'
)"

[[ -z "${query}" ]] && exit 0

nix search nixpkgs "${query}" --json | jq -j '
  to_entries
  | map(
      .key as $pkg
      | (.value.version // "unknown") as $ver
      | (.value.description // "") as $desc
      | "\($pkg)\u0000display\u001f"
        + (@html "\($pkg) (\($ver))\n<span size=\"small\" alpha=\"70%\">\($desc)</span>")
    )
  | join("|")
' | rofi -dmenu -i -p 'Choose package:' -markup-rows -eh 2 -sep "|" |
    sed 's/^.*\.//' |
    sort |
    wl-copy
