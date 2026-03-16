{ config, lib, pkgs, nixpkgs-unstable, ... }:
let
  # https://github.com/davatorium/rofi/issues/584#issuecomment-384555551
  askPass = pkgs.writeShellScriptBin "ask-pass" ''
    rofi -dmenu \
        -password \
        -no-fixed-num-lines \
        -p "$(printf "$1" | sed s/://)"
  '';
in {
  imports = [
    ./shared.nix
    ./modules/dunst.nix
    ./modules/firefox.nix
    ./modules/lan-mouse.nix
    ./modules/waybar/waybar.nix
  ];

  home.username = "andy";
  home.homeDirectory = "/home/andy";

  home.packages = with pkgs; [
    grim # screenshot tool
    imv # command-line image viewer
    killall
    mangohud
    moonlight-qt
    mpv # command-line media player
    slskd
    slurp # select region of screen
    swappy # screenshot annotation tool
    tcpdump
    traceroute
    trash-cli
    xfce.thunar
    (pkgs.writeShellScriptBin "firefox-vpn" ''
      USER_ID=$(id -u)
      XDG_RUNTIME_DIR=/run/user/$USER_ID

      SUDO_ASKPASS=${askPass}/bin/ask-pass \
        sudo -A ip netns exec vpn \
          sudo -u $(whoami) \
            ${pkgs.bubblewrap}/bin/bwrap \
              --dev-bind / / \
              --unshare-ipc \
              ${pkgs.dbus}/bin/dbus-run-session \
                env \
                  XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR \
                  PULSE_SERVER=unix:$XDG_RUNTIME_DIR/pulse/native \
                  DISPLAY="$DISPLAY" \
                  WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
                  ${pkgs.firefox}/bin/firefox -no-remote "$@"
    '')
  ];

  home.sessionVariables = { MOZ_ENABLE_WAYLAND = "1"; };

  wayland.windowManager.river = {
    enable = true;
    systemd = { enable = true; };
    extraConfig = builtins.readFile ./river/init;
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    font = lib.mkForce "CaskaydiaCove Nerd Font 14";
    theme = { "*" = { padding = config.lib.formats.rasi.mkLiteral "3px"; }; };
    extraConfig = { markup-rows = true; };
  };

  services.swayidle = {
    enable = true;
    systemdTarget = "river-session.target";
    timeouts = [
      {
        timeout = 1740;
        command =
          "${pkgs.dunst}/bin/dunstify --urgency=normal 'Locking session in 1 minute'";
      }
      {
        timeout = 1800;
        command = "${pkgs.wlopm}/bin/wlopm --off '*'";
        resumeCommand = "${pkgs.wlopm}/bin/wlopm --on '*'";
      }
    ];
  };

  services.udiskie = {
    enable = true;
    settings = {
      program_options = { file_manager = "${pkgs.xfce.thunar}/bin/thunar"; };
    };
  };
}
