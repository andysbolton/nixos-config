#/usr/bin/env bash

curr_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

nixos-generate-config --no-filesystems --show-hardware-config > "$curr_dir/hardware-configuration.nix"

nix --experimental-features "nix-command flakes" \
    run "github:nix-community/disko/latest#disko-install" -- \
    --write-efi-boot-entries \
    --flake ~/nixos-config#hub \
    --disk main /dev/nvme0n1 \
    --show-trace
