{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [
      ./hosts/hub/hardware-configuration.nix
      ./hosts/hub/disko.nix
      inputs.sops-nix.nixosModules.sops
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.grub.enable = true;
  #boot.loader.grub.efiSupport = true;
  #boot.loader.grub.efiInstallAsRemovable = true;

  networking.hostName = "hub";
  networking.wireless = {
    userControlled.enable = true;
    enable = true;
    secretsFile = config.sops.secrets."wireless.conf".path;
    extraConfig = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel";
    networks = {
      "BBBP_5G".pskRaw = "ext:psk";
    };
  };

  # Set your time zone.
  time.timeZone = "America/Mountain";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  services.spice-vdagentd.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.andy = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.fish;
    packages = with pkgs; [
      firefox
      tree
    ];
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    grim # screenshot functionality
    mako # notification system developed by swaywm maintainer
    neovim
    pkgs._1password-cli
    pkgs.age
    pkgs.asdf-vm
    pkgs.bat
    pkgs.btop
    pkgs.chezmoi
    pkgs.delta
    pkgs.fish
    pkgs.gcc
    pkgs.gh
    pkgs.gnumake
    pkgs.sops
    pkgs.spice-vdagent
    pkgs.starship
    pkgs.unzip
    pkgs.wezterm
    slurp # screenshot functionality
    wget
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
  ];

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
   (nerdfonts.override { fonts = [ "CascadiaCode" ]; })
   cascadia-code
  ];

  # fonts.packages = [
  #   pkgs.nerd-fonts.caskaydia-cove
  # ];

  # Enable the gnome-keyring secrets vault.
  # Will be exposed through DBus to programs willing to store secrets.
  services.gnome.gnome-keyring.enable = true;

  # enable Sway window manager
  # programs.sway = {
  #  enable = true;
  #  wrapperFeatures.gtk = true;
  # };

  programs.fish.enable = true;

  # services.greetd = {
  #  enable = true;
  #  settings = {
  #    default_session = {
  #      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd sway";
  #      user = "greeter";
  #    };
  #  };
  # };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  sops.defaultSopsFile = ./secrets/sops.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/andy/.config/sops/age/keys.txt";
  sops.secrets."wireless.conf" = { };

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
