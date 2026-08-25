{
  stdenv,
  writeShellScriptBin,
  jq,
  qemu,
  repoPath,
  vmDir,
}:

let
  inherit (stdenv.hostPlatform) isDarwin qemuArch;

  machine = if isDarwin then "virt" else "q35";
  accel = if isDarwin then "hvf" else "kvm";
  display = if isDarwin then "cocoa,full-screen=on,full-grab=on" else "gtk,full-screen=on";
in
writeShellScriptBin "jetkvm-kiosk" ''
  set -e

  mkdir -p "${vmDir}"
  # --out-link roots the image against GC; the overlay's backing file lives
  # in the store, so without a root a GC would corrupt the overlay.
  nix build ${repoPath}#nixosConfigurations.jetkvm-kiosk-${qemuArch}.config.system.build.images.qemu-efi \
    --out-link "${vmDir}/jetkvm-kiosk-base"
  base=$(echo "$(readlink -f "${vmDir}/jetkvm-kiosk-base")"/*.qcow2)
  overlay="${vmDir}/jetkvm-kiosk-overlay.qcow2"
  cur=$(${qemu}/bin/qemu-img info --output=json "$overlay" 2>/dev/null | ${jq}/bin/jq -r '."backing-filename" // empty')

  if [ "$cur" != "$base" ]; then
    echo "New base image, recreating overlay..."
    ${qemu}/bin/qemu-img create -f qcow2 -F qcow2 -b "$base" "$overlay"
  fi

  exec ${qemu}/bin/qemu-system-${qemuArch} \
    -name jetkvm-kiosk \
    -machine ${machine} \
    -accel ${accel} \
    -cpu host \
    -m 2G \
    -smp 2 \
    -nic user,model=virtio-net-pci \
    -drive file="$overlay",if=virtio \
    -drive if=pflash,format=raw,readonly=on,file=${qemu}/share/qemu/edk2-${qemuArch}-code.fd \
    -device virtio-gpu-pci \
    -display ${display} \
    -device qemu-xhci \
    -device usb-kbd \
    -device usb-tablet \
    "$@"
''
