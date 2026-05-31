{
  config,
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/desktop.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "portable";
  networking.networkmanager.enable = true;

  users.users.andy.extraGroups = [
    "wheel"
    "networkmanager"
  ];

  environment.systemPackages = with pkgs; [
    moonlight-qt
    waypipe
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  hardware.graphics.enable = true;

  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];

  system.stateVersion = "25.11";
}
