{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./_monitors.nix
    inputs.self.modules.nixos.base
  ];

  boot.plymouth.enable = true;

  time.timeZone = "America/Denver";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    keyMap = "us";
  };

  stylix.targets.plymouth.colors.enable = true;
  stylix.targets.limine.enable = true;
  boot.loader.limine.style.wallpapers = [ config.theme.wallpaper ];
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  security.rtkit.enable = true;

  # SuperCollider's scsynth requests realtime scheduling directly (not via rtkit).
  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "99";
    }
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
  ];

  services.weechat.enable = true;

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

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
    "pipe-operators"
  ];

  environment.systemPackages = with pkgs; [
    brightnessctl
    lxqt.lxqt-policykit
    man-pages
    man-pages-posix
    pavucontrol
    swaylock
    wl-clipboard
    wlopm
    wlr-randr
    xdpyinfo
    xrandr
  ];

  fonts.fontDir.enable = true;

  stylix.enable = true;
  stylix.autoEnable = false;
  stylix.homeManagerIntegration.autoImport = false;
  stylix.targets.console.enable = true;
  stylix.targets.kmscon.enable = true;

  services.gnome.gnome-keyring.enable = true;

  programs.river-classic = {
    enable = true;
    extraPackages = [ ];
  };

  xdg.portal.wlr.settings.screencast = {
    chooser_type = "dmenu";
    chooser_cmd = "${pkgs.rofi}/bin/rofi -dmenu -p share";
  };

  programs.uwsm = {
    enable = true;
    waylandCompositors.river = {
      prettyName = "River";
      comment = "River compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/river";
    };
  };

  # Truecolor TTYs with TTF fonts on VT2 and up; greetd keeps VT1.
  services.kmscon = {
    enable = true;
    term = "xterm-256color";
  };

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "uwsm start river.desktop";
        user = "andy";
      };
      default_session = {
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet --time --cmd "uwsm start river.desktop"
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

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = lib.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users);
  };

  users.users.andy.extraGroups = [
    "1password"
    "audio"
  ];

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
  services.dbus.enable = true;
  services.blueman.enable = true;
  services.udisks2.enable = true;
  security.polkit.enable = true;

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  documentation = {
    enable = true;
    man.enable = true;
    dev.enable = true;
  };
}
