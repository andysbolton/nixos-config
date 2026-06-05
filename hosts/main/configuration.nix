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
    ../../modules/hardware.nix
    ../../modules/arrs.nix
    ../../modules/torrenting.nix
    ../../modules/steam.nix
    ../../modules/vpn.nix
    ../../modules/wireless.nix
    inputs.sops-nix.nixosModules.sops
    # inputs.wayland-pipewire-idle-inhibit.nixosModules.default
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.extraModulePackages = [ pkgs.linuxPackages_zen.nct6687d ];
  boot.kernelModules = [ "nct6687" ];
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];

  networking.hostName = "main";

  modules.wireless = {
    enable = true;
    ssid = "Hammy 5 GHz";
    secretsFile = config.sops.secrets."wireless.conf".path;
  };

  users.users.andy.extraGroups = [
    "docker"
    "wheel"
    "wpa_supplicant"
  ];

  sops = {
    defaultSopsFile = ../../secrets/main.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets."wireless.conf" = {
      owner = "wpa_supplicant";
      group = "wpa_supplicant";
      mode = "0440";
    };
    secrets."proton-vpn.conf" = { };
    secrets."radarr_api_key" = {
      owner = "unpackerr";
      group = "media";
      mode = "0440";
    };
  };

  networking.firewall.allowedUDPPorts = [
    4242 # lan-mouse
    32400 # Plex Media Server
  ];
  networking.firewall.allowedTCPPorts = [
    32400 # Plex Media Server
  ];

  environment.systemPackages = with pkgs; [
    # TODO: move or remove this.
    (retroarch.withCores (
      cores: with cores; [
        genesis-plus-gx
        snes9x
      ]
    ))
  ];

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  # Revisit, this may all be set by programs.river.enable = true;
  # xdg.portal = {
  #   enable = true;
  #   wlr.enable = true;
  #   configPackages =
  #     [ pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk ];
  # };

  modules.arrs = {
    radarr.enable = true;
    sonarr.enable = true;
    prowlarr = {
      enable = true;
      addUserToMediaGroup = false;
    };
  };

  modules.vpn = {
    enable = true;
    dns = "10.2.0.1";
    ip = "10.2.0.2/32";
    netns = "vpn";
    wgConfPath = config.sops.secrets."proton-vpn.conf".path;
  };

  services.sunshine = {
    enable = true;
    openFirewall = true;
    capSysAdmin = true;
    settings = {
      capture = "kms";
      encoder = "nvenc";
    };
  };

  services.printing.enable = true;
  # Arkscan/Zebra usually works with standard CUPS drivers,
  # but gutenprint provides extra compatibility if needed.
  services.printing.drivers = [ pkgs.gutenprint ];

  virtualisation.docker = {
    enable = true;
  };

  systemd.settings.Manager = {
    ShowStatus = "Yes";
  };

  # services.wayland-pipewire-idle-inhibit = {
  #   enable = true;
  #   systemdTarget = "river-session.target";
  #   settings = {
  #     verbosity = "INFO";
  #     media_minimum_duration = 10;
  #     idle_inhibitor = "wayland";
  #     sink_whitelist = [ ];
  #     node_blacklist = [ ];
  #   };
  # };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
