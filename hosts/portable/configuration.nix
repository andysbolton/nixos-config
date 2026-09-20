{
  config,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/theme.nix
    ../../modules/desktop.nix
    ../../modules/steam.nix
    ../../modules/vpn.nix
    ../../modules/wireless.nix
    inputs.sops-nix.nixosModules.sops
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "portable";
    firewall = {
      allowedUDPPorts = [ config.services.tailscale.port ];
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  system.stateVersion = "26.05";
}
