#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

host_dir=""
host=""
sops=false
target=""

while [ $# -gt 0 ]; do
  case "$1" in
  --target)
    if [ -z "${2:-}" ]; then
      echo "--target needs a value, e.g. --target 192.168.1.155" >&2
      exit 1
    fi
    target="$2"
    shift 2
    ;;
  --dir)
    if [ -z "${2:-}" ]; then
      echo "--dir needs a value." >&2
      exit 1
    fi
    host_dir="$(basename "$2")"
    shift 2
    ;;
  --sops)
    sops=true
    shift 1
    ;;
  *)
    host="$1"
    shift
    ;;
  esac
done

if [ -z "$host_dir" ]; then
  host_dir="$host"
fi

if [ -n "$target" ]; then
  mode=remote
  if [ "$EUID" -eq 0 ]; then
    echo "Remote mode runs on your own machine; don't run it as root" >&2
    exit 1
  fi
else
  mode=local
  if [ "$EUID" -ne 0 ]; then
    echo "Local mode must be run as root (sudo ./install.sh)" >&2
    exit 1
  fi
fi

if [ -z "$host" ] || ! [ -d "$repo_dir/hosts/$host_dir" ]; then
  echo "Unknown host. Check out the hosts/ folder for options." >&2
  exit 1
fi

function local_install() {
  echo "Generating hardware configuration..."
  nixos-generate-config --no-filesystems --show-hardware-config \
    >"$repo_dir/hosts/$host_dir/hardware-configuration.nix"

  chown -R "$SUDO_USER": "$repo_dir/hosts/$host_dir"
  sudo -u "$SUDO_USER" git -C "$repo_dir" add "$repo_dir/hosts/$host_dir/"

  echo "Partitioning and mounting disk..."
  nix --experimental-features "nix-command flakes pipe-operators" \
    run "github:nix-community/disko#disko" -- \
    --mode disko \
    --flake "$repo_dir#$host"

  cp -a "$stage"/. /mnt

  echo "Installing NixOS..."
  nixos-install \
    --root /mnt \
    --flake "$repo_dir#$host" \
    --no-root-password
}

function remote_install() {
  nixos-anywhere \
    --generate-hardware-config nixos-generate-config "$repo_dir"/hosts/"$host_dir"/hardware-configuration.nix \
    --extra-files "$stage" \
    --flake "$repo_dir#$host" root@"$target"

  git add "$repo_dir/hosts/$host_dir"
}

echo "Installing '$host' ($mode${target:+ to $target})"

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
chmod 755 "$stage"

if [ "$sops" = true ]; then
  echo "Pre-generating SSH host key..."

  ssh_dir=$stage/etc/ssh
  keys_dir="$repo_dir/hosts/$host_dir/keys"

  install -d -m 755 "$ssh_dir"
  ssh-keygen -q -t ed25519 -f "$ssh_dir/ssh_host_ed25519_key" -N "" -C "" </dev/null
  mkdir -p "$keys_dir"
  nix --experimental-features "nix-command flakes" run nixpkgs#ssh-to-age -- <"$ssh_dir/ssh_host_ed25519_key.pub" >"$keys_dir/age.pub"
fi

if [ "$mode" == "remote" ]; then
  remote_install
else
  local_install
fi
