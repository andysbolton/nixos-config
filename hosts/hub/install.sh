#/usr/bin/env bash

curr_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount "$curr_dir/hub/disko.nix"

nixos-generate-config --no-filesystems --show-hardware-config > "$curr_dir/hardware-configuration.nix"

nixos-install --no-root-password --flake ~/nixos-config#hub
