{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  # https://github.com/davatorium/rofi/issues/584#issuecomment-384555551
  askPass = pkgs.writeShellScriptBin "ask-pass" ''
    rofi -dmenu \
        -password \
        -no-fixed-num-lines \
        -p "$(printf "$1" | sed s/://)"
  '';
in
{
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
    cliphist
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
      SUDO_ASKPASS=${askPass}/bin/ask-pass \
         sudo -A -E ip netns exec vpn \
           sudo -E -u $(whoami) \
             ${pkgs.firefox}/bin/firefox -no-remote "$@"
    '')
  ];

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    # MOZ_DISABLE_RDD_SANDBOX = "1";
  };

  wayland.windowManager.river = {
    enable = true;
    systemd.enable = false;
    extraConfig = builtins.readFile ./river/init;
  };

  programs.rofi = {
    enable = true;
    font = lib.mkForce "CaskaydiaCove Nerd Font 14";
    theme = {
      "*" = {
        padding = config.lib.formats.rasi.mkLiteral "3px";
      };
    };
    extraConfig = {
      markup-rows = true;
    };
  };

  services.swayidle = {
    enable = true;
    systemdTarget = "river-session.target";
    timeouts = [
      {
        timeout = 1740;
        command = "${pkgs.dunst}/bin/dunstify --urgency=normal 'Locking session in 1 minute'";
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
      program_options = {
        file_manager = "${pkgs.xfce.thunar}/bin/thunar";
      };
    };
  };
}
