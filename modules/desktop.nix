{
  pkgs,
  lib,
  config,
  ...
}:
{
  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  users.users.andy = {
    isNormalUser = true;
    shell = pkgs.fish;
  };

  # Real hosts keep andy's password in /etc/shadow; a build-vm guest starts empty.
  virtualisation.vmVariant.users.users = {
    andy.initialPassword = "vm";
    root.initialPassword = "vm";
  };

  # Real hosts force a GPU renderer (see home-manager/linux.nix); a build-vm guest has no GPU,
  # so wlroots needs the software renderer or river fails to start.
  virtualisation.vmVariant.home-manager.users.andy.xdg.configFile."uwsm/env-river".text =
    lib.mkVMOverride ''
      export WLR_NO_HARDWARE_CURSORS=1
      export WLR_RENDERER=pixman
      export WLR_RENDERER_ALLOW_SOFTWARE=1
    '';

  programs.fish = {
    enable = true;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    brightnessctl
    lxqt.lxqt-policykit
    pavucontrol
    swaylock
    wl-clipboard
    wlopm
    wlr-randr
    xdpyinfo
    xrandr
  ];

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    nerd-fonts.symbols-only
    noto-fonts-color-emoji
    last-resort
  ];

  services.gnome.gnome-keyring.enable = true;

  programs.river-classic = {
    enable = true;
    extraPackages = [ ];
  };

  programs.uwsm = {
    enable = true;
    waylandCompositors.river = {
      prettyName = "River";
      comment = "River compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/river";
    };
  };

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "uwsm start river-uwsm.desktop";
        user = "andy";
      };
      default_session = {
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet --time --cmd "uwsm start river-uwsm.desktop"
        '';
        user = "greeter";
      };
    };
  };

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  services.openssh.enable = true;
  services.eternal-terminal.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = lib.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users);
  };

  users.groups.ssh-keys = { };
  users.users.andy.extraGroups = [
    "ssh-keys"
    "1password"
  ];
  systemd.tmpfiles.rules = [
    "f /etc/ssh/ssh_host_ed25519_key 0640 root ssh-keys -"
  ];
  services.tailscale.enable = true;

  systemd.services.tailscaled = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  services.resolved.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      hinfo = true;
      workstation = true;
    };
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  services.dbus.enable = true;
  services.blueman.enable = true;
  services.udisks2.enable = true;
  security.polkit.enable = true;

  virtualisation.podman = {
    enable = true;
  };

}
