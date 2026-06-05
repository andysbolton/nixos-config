{
  pkgs,
  pkgs-unstable,
  lib,
  config,
  ...
}:
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
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAAGFGipKjoh/k9IHbfE00n4p5rnMMvsYNMS/Pbx3IE6SgoGSEPSFOxSiNsX7thhyT55fkDoQPaMr+0hGwaz+qeYpbInWfsZLjZOn5iqMgmqCPX5khe2UW+J9dPlAj5eCv2OCzNjbevnFU1MOlw1X26BbzdFS1VOd3OKmS72jEYOvQK7C/ciAj/ytlh+9NwJFcaUugXWJShhi6XMzfPWTDSTwcFlKfOH4n5uyRj7qi1ZGg8w9qnaSSIhaACgOGRXmfDoaVBCZx1fjeBYL9SeZMiIeCy3i2CPiUuKuVebP3p7DbavWq2055NSLQUK5MKfFeFJUHCgYtMOtckcv5SMR5 andy-rsa"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK3wN9/LQcWF0pun3XaCnRfNnIiMbJlCxG2tZl3n9I3c andy-ed25519"
    ];
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
    xrandr
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

}
