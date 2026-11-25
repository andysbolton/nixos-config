{
  config,
  inputs,
  ...
}:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    inputs.self.modules.nixos.base
    inputs.self.modules.nixos.fleet
    inputs.self.modules.nixos.headless
  ];

  # Remove after referencing hardware.nix
  nixpkgs.hostPlatform = "x86_64-linux";

  networking = {
    hostName = config.fleet.device.name;
    useNetworkd = true;
    useDHCP = false;
  };

  systemd.network = {
    enable = true;
    config.networkConfig.UseDomains = true;
    networks.lan = {
      DHCP = "yes";
      matchConfig = {
        Type = "ether";
      };
    };
  };

  system.stateVersion = "26.05";
}
