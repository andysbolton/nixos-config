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
    ../../modules/wireless.nix
    inputs.sops-nix.nixosModules.sops
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "portable";

  users.users.andy.extraGroups = [
    "wheel"
    "wpa_supplicant"
  ];

  modules.wireless = {
    enable = true;
    ssid = "Hammy 5 GHz";
    secretsFile = config.sops.secrets."wireless.conf".path;
  };

  environment.systemPackages = with pkgs; [
    moonlight-qt
    waypipe
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  hardware.graphics.enable = true;

  sops = {
    defaultSopsFile = ../../secrets/sops.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.users.users.andy.home}/.config/sops/age/keys.txt";
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];

  system.stateVersion = "26.05";
}
