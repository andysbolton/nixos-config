{ config, lib, pkgs, inputs, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ./disko.nix
      inputs.sops-nix.nixosModules.sops
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
    networks = {
      "BBBP_5G".pskRaw = "ext:psk";
    };
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
      firefox
      mangohud
      go
      nodejs_22
      tree
      tofi
      solaar
      sunshine
      moonlight-qt
    ];
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Note for future:
  # is asdf still installed even though I removed it from systemPackages?
  environment.systemPackages = with pkgs; [
    _1password-cli
    _1password-gui
    age
    bat
    btop
    chezmoi
    delta
    discord
    dunst
    egl-wayland
    fd
    file
    fish
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
    lm_sensors
    lsd
    lua-language-server
    lynx
    mozlz4a
    overskride
    pavucontrol
    procs
    python314
    ripgrep
    river
    rofi
    sops
    starship
    swayidle
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
  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
  ];

  # Enable the gnome-keyring secrets vault.
  # Will be exposed through DBus to programs willing to store secrets.
  services.gnome.gnome-keyring.enable = true;

  programs.fish.enable = true;
  # programs.bash = {
  #   interactiveShellInit = ''
  #     if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
  #     then
  #       shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
  #       exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
  #     fi
  #   '';
  # };

  programs.river = {
    enable = true;
  };

  programs.waybar = {
    enable = true;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "andy" = ../../home-manager/home.nix;
    };
  };

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
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd \"dbus-run-session river\"";
        user = "greeter";
      };
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.dbus.enable = true;

  services.blueman.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  networking.firewall.allowedUDPPorts = [ 4242 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  sops = {
    defaultSopsFile = ../../secrets/sops.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/andy/.config/sops/age/keys.txt";
    secrets."wireless.conf" = { };
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
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
