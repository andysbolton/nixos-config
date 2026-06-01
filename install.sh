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

SOPS_FILE="$repo_dir/secrets/$HOST.yaml"
if [ ! -f "$SOPS_FILE" ]; then
  echo "Pre-generating SSH host key..."
  mkdir -p /mnt/etc/ssh
  ssh-keygen -t ed25519 -f /mnt/etc/ssh/ssh_host_ed25519_key -N "" -C ""

  SSH_PUBKEY=$(cat /mnt/etc/ssh/ssh_host_ed25519_key.pub)

  read -rsp "WiFi PSK: " WIFI_PSK
  echo

  TMPFILE=$(mktemp)
  trap 'rm -f $TMPFILE' EXIT
  printf 'wireless.conf: "%s"\n' "$WIFI_PSK" >"$TMPFILE"
  nix-shell -p sops --run \
    "SOPS_AGE_RECIPIENTS='$SSH_PUBKEY' sops --encrypt --input-type yaml --output-type yaml '$TMPFILE'" \
    >"$SOPS_FILE"
  echo "Created $SOPS_FILE"
fi

echo "Installing NixOS..."
nixos-install \
  --root /mnt \
  --flake "$repo_dir#$HOST" \
  --no-root-password

nixos-enter --command "echo 'Set password for andy:' && passwd andy"

echo
echo "Installation complete. Remember to commit:"
echo "  hosts/$HOST/hardware-configuration.nix"
echo "  secrets/$HOST.yaml"
