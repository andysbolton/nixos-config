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

echo
echo "Available disks:"
lsblk -dpno NAME,SIZE,MODEL | awk '!/loop/'

mapfile -t disks < <(lsblk -dpno NAME,TYPE | awk '$2=="disk"{print $1}')

if [ ${#disks[@]} -eq 0 ]; then
  echo "No disks found."
  exit 1
elif [ ${#disks[@]} -eq 1 ]; then
  disk="${disks[0]}"
  echo "Auto-selected: $disk"
else
  echo
  PS3="Select disk to install onto: "
  select disk in "${disks[@]}"; do
    [ -n "$disk" ] && break
  done
fi

echo
echo "WARNING: All data on $disk will be permanently erased."
read -rp "Type 'yes' to continue: " confirm
[ "$confirm" = "yes" ] || {
  echo "Aborted."
  exit 1
}

nix --experimental-features "nix-command flakes" \
  run "github:nix-community/disko#disko" -- \
  --mode destroy,format,mount \
  --flake "$repo_dir#$HOST" \
  --disk main "$disk" \
  --show-trace

nixos-install --no-root-password --flake "$repo_dir#$HOST" --show-trace

nixos-enter --command "echo 'Set password for andy:' && passwd andy"

echo
echo "Installation complete. Remember to commit the generated hardware config:"
echo "  hosts/$HOST/hardware-configuration.nix"
