#!/usr/bin/env bash

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

nixos-generate-config --no-filesystems --show-hardware-config >"$script_dir/hardware-configuration.nix"

nix --experimental-features "nix-command flakes" \
    run "github:nix-community/disko#disko-install" -- \
    --write-efi-boot-entries \
    --flake .#main \
    --disk main /dev/sda \
    --show-trace

mount /dev/disk/by-partlabel/disk-main-root /mnt
nixos-enter --command "echo \"Add new password for user 'andy'\" && passwd andy"
umount /dev/disk/by-partlabel/disk-main-root

# Addendum:
# If you need to add any additional disks after the initial installation, you can use the following command, after adding the relevant disk configurations to disko.nix:
# disko --mode format --dry-run disko.nix
# See: https://github.com/nix-community/disko/pull/568
