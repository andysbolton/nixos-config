{ config, lib, pkgs, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    inputs.sops-nix.nixosModules.sops
    inputs.wayland-pipewire-idle-inhibit.nixosModules.default
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.extraModulePackages = [ pkgs.linuxPackages_zen.nct6687d ];
  boot.kernelModules = [ "nct6687" ];
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];

  networking.hostName = "home";
  networking.wireless = {
    userControlled.enable = true;
    enable = true;
    secretsFile = config.sops.secrets."wireless.conf".path;
    extraConfig = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel";
    networks = { "BBBP_5G".pskRaw = "ext:psk"; };
  };

  time.timeZone = "America/Denver";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Enable sound.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  users.users.andy = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    packages = with pkgs; [
      go
      grim # screenshot tool
      imv # command-line image viewer
      lf # terminal file manager
      mangohud
      moonlight-qt
      mpv # command-line media player
      slurp # select region of screen
      solaar
      starship
      sunshine
      swappy # screenshot annotation tool
      tree
    ];
  };

  programs.fish.enable = true;

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Note for future:
  # is asdf still installed even though I removed it from systemPackages?
  environment.systemPackages = with pkgs; [
    (retroarch.withCores (cores: with cores; [ genesis-plus-gx snes9x ]))
    _1password-cli
    _1password-gui
    age
    bat
    chezmoi
    chromium
    delta
    dig
    discord
    # egl-wayland
    fd
    file
    fzf
    gcc
    gh
    git
    gnumake
    heroic
    httpie
    jq
    killall
    lan-mouse
    libnatpmp
    lm_sensors
    lsd
    lxqt.lxqt-policykit
    lynx
    nh
    pavucontrol
    procs
    python314
    ripgrep
    sops
    swaylock
    trash-cli
    unzip
    wezterm
    wget
    wl-clipboard
    wlopm
    xorg.xdpyinfo # check resolution
    zoxide
  ];

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [ nerd-fonts.caskaydia-cove ];

  # Enable the gnome-keyring secrets vault.
  # Will be exposed through DBus to programs willing to store secrets.
  services.gnome.gnome-keyring.enable = true;

  stylix.enable = true;
  stylix.autoEnable = true;
  stylix.base16Scheme =
    "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
  stylix.targets.fish.enable = false;

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Without this errors will spam on screen
    # Without these bootlogs will spam on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd "river"
        '';
        user = "greeter";
      };
    };
  };

  services.openssh.enable = true;
  services.dbus.enable = true;
  services.blueman.enable = true;

  networking.firewall.allowedUDPPorts = [
    4242 # lan-mouse
    32400 # Plex Media Server
  ];
  networking.firewall.allowedTCPPorts = [
    32400 # Plex Media Server
  ];

  services.udisks2.enable = true;

  sops = {
    defaultSopsFile = ../../secrets/sops.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/andy/.config/sops/age/keys.txt";
    secrets."wireless.conf" = { };
    secrets."proton-vpn.conf" = { };
  };
  security.polkit.enable = true;

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    configPackages =
      [ pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk ];
  };

  services.wayland-pipewire-idle-inhibit = {
    enable = true;
    systemdTarget = "river-session.target";
    settings = {
      verbosity = "INFO";
      media_minimum_duration = 10;
      idle_inhibitor = "wayland";
      sink_whitelist = [ ];
      node_blacklist = [ ];
    };
  };

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
