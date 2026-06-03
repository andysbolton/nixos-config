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

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [ "https://lan-mouse.cachix.org" ];
    extra-trusted-public-keys = [
      "lan-mouse.cachix.org-1:KlE2AEZUgkzNKM7BIzMQo8w9yJYqUpor1CAUNRY6OyM="
    ];
  };

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

  users.groups.ssh-keys = { };
  users.users.andy.extraGroups = [ "ssh-keys" ];
  systemd.tmpfiles.rules = [
    "f /etc/ssh/ssh_host_ed25519_key 0640 root ssh-keys -"
  ];
  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  services.dbus.enable = true;
  services.blueman.enable = true;
  services.udisks2.enable = true;
  security.polkit.enable = true;
}
