#!/usr/bin/env bash

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

nixos-generate-config --no-filesystems --show-hardware-config >"$script_dir/hardware-configuration.nix"

nix --experimental-features "nix-command flakes" \
    run "github:nix-community/disko#disko-install" -- \
    --write-efi-boot-entries \
    --flake "$script_dir/../.."#home \
    --disk main /dev/nvme0n1 \
    --show-trace

mount /dev/disk/by-partlabel/disk-main-root /mnt
nixos-enter --command "echo \"Add new password for user 'andy'\" && passwd andy"
umount /dev/disk/by-partlabel/disk-main-root
