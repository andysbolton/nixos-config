{ inputs, pkgs, ... }: {
  imports = [ inputs.lan-mouse.homeManagerModules.default ];
  programs.lan-mouse = {
    enable = true;
    systemd = true;
    # package = inputs.lan-mouse.packages.${pkgs.stdenv.hostPlatform.system}.default
    # Optional configuration in nix syntax, see config.toml for available options
    settings = let
      # we can't use any ${pkgs} proper path,
      # because it also runs commands on the remote machine
      shareClipboard = dest:
        "wl-paste --no-newline | ssh ${dest} -i .ssh/id_home_nokey env WAYLAND_DISPLAY='wayland-1' wl-copy";
    in {
      release_bind = [ "KeyA" "KeyS" "KeyD" "KeyF" ];
      port = 4242;
      frontend = "cli";
      # right = {
      #   hostname = "crom";
      #   activate_on_startup = true;
      #   enter_hook = shareClipboard "crom";
      #   ips = [ "192.168.1.2" ];
      # };
      left = {
        hostname = "work";
        activate_on_startup = true;
        ips = [ ];
        # enter_hook = shareClipboard "fw";
        # ips = [ "192.168.1.3" ];
      };
    };
  };

  systemd.user.services.lan-mouse.Install.WantedBy = [ "river-session.target" ];

  # release_bind = [ "Key", "KeyS", "KeyD", "KeyF" ]
  #
  # port = 4242
  # frontend = "cli"
  #
  # [left]
  # hostname = "work"
  # activate_on_startup = true
  # ips = []

  # systemd.user.services.lan-mouse.Service.Environment =
  #   "PATH=$PATH:/run/current-system/sw/bin";
}
