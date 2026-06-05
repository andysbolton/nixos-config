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

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  sops = {
    defaultSopsFile = ../../secrets/portable.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    gnupg.sshKeyPaths = [ ];
    secrets."wireless.conf" = {
      owner = "wpa_supplicant";
      group = "wpa_supplicant";
      mode = "0440";
    };
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];

  system.stateVersion = "26.05";
}
