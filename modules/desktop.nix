{ pkgs, pkgs-unstable, ... }:
{
  time.timeZone = "America/Denver";

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

  programs.fish = {
    enable = true;
    package = pkgs-unstable.fish;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    lxqt.lxqt-policykit
    pavucontrol
    swaylock
    wl-clipboard
    wlopm
    xdpyinfo
  ];

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [ nerd-fonts.caskaydia-cove ];

  services.gnome.gnome-keyring.enable = true;

  programs.river-classic.enable = true;

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
  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  services.dbus.enable = true;
  services.blueman.enable = true;
  services.udisks2.enable = true;
  security.polkit.enable = true;
}
