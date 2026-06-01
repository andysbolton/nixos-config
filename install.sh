#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root (sudo ./install.sh)"
  exit 1
fi

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

HOST="${1:-}"

if [ -z "$HOST" ]; then
  mapfile -t hosts < <(ls -1 "$repo_dir/hosts/")
  PS3="Select host to install: "
  select HOST in "${hosts[@]}"; do
    [ -n "$HOST" ] && break
  done
fi

if [ ! -d "$repo_dir/hosts/$HOST" ]; then
  echo "Unknown host: $HOST"
  exit 1
fi

echo "Generating hardware configuration..."
nixos-generate-config --no-filesystems --show-hardware-config \
  >"$repo_dir/hosts/$HOST/hardware-configuration.nix"

echo "Partitioning and mounting disk..."
nix --experimental-features "nix-command flakes" \
  run "github:nix-community/disko#disko" -- \
  --mode disko \
  --flake "$repo_dir#$HOST"

echo "Installing NixOS..."
nixos-install \
  --root /mnt \
  --flake "$repo_dir#$HOST" \
  --no-root-password

nixos-enter --command "echo 'Set password for andy:' && passwd andy"

echo
echo "Installation complete. Remember to commit the generated hardware config:"
echo "  hosts/$HOST/hardware-configuration.nix"
