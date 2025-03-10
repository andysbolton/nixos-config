#!/usr/bin/env bash

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

nix --experimental-features "nix-command flakes" run "github:nix-community/disko/latest" -- --mode destroy,format,mount "$script_dir/disko.nix"

nixos-generate-config --no-filesystems --show-hardware-config >"$script_dir/hardware-configuration.nix"

nixos-install --no-root-password --flake "$script_dir/../.."#hub
