#!/usr/bin/env bash
set -euo pipefail

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

if ! ping -c 1 -W 3 github.com &>/dev/null; then
  iface=$(for dev in /sys/class/net/*/; do
    [ -d "${dev}wireless" ] && basename "$dev" && break
  done)

  if [ -z "$iface" ]; then
    echo "No wireless interface found and no network connectivity. Connect manually and retry."
    exit 1
  fi

  echo "No network detected. Connecting via $iface..."
  read -rp "WiFi SSID: " ssid
  read -rsp "WiFi password: " password
  echo

  wpa_passphrase "$ssid" "$password" > /tmp/wpa.conf
  wpa_supplicant -B -i "$iface" -c /tmp/wpa.conf
  dhcpcd "$iface"

  echo -n "Waiting for connection"
  until ping -c 1 -W 2 github.com &>/dev/null; do
    echo -n "."
    sleep 1
  done
  echo " connected."
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
  run "github:nix-community/disko#disko-install" -- \
  --write-efi-boot-entries \
  --flake "$repo_dir#$HOST" \
  --disk main "$disk" \
  --show-trace

mount /dev/disk/by-partlabel/disk-main-root /mnt
nixos-enter --command "echo 'Set password for andy:' && passwd andy"
umount /dev/disk/by-partlabel/disk-main-root

echo
echo "Installation complete. Remember to commit the generated hardware config:"
echo "  hosts/$HOST/hardware-configuration.nix"
