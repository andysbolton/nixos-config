{ pkgs, modulesPath, ... }: {
  imports = [ "${modulesPath}/profiles/minimal.nix" ];

  disabledModules = [ "${modulesPath}/profiles/all-hardware.nix" ];

  services.cage = {
    enable = true;
    user = "kvm";
    program = "${pkgs.firefox}/bin/firefox --kiosk http://192.168.8.117"; # change to tailscale tunnel
  };
  users.users.kvm.isNormalUser = true;

  networking.useDHCP = true;
  services.qemuGuest.enable = true;

  system.stateVersion = "25.05";
}
