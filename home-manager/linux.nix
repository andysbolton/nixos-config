{
  config,
  lib,
  pkgs,
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
    mpv # command-line media player
    slskd
    slurp # select region of screen
    swappy # screenshot annotation tool
    tcpdump
    traceroute
    waypipe
    trash-cli
    thunar
    (pkgs.writeShellScriptBin "firefox-vpn" ''
      SUDO_ASKPASS=${askPass}/bin/ask-pass \
         sudo -A -E ip netns exec vpn \
           sudo -E -u $(whoami) \
             ${pkgs.firefox}/bin/firefox -no-remote "$@"
    '')
  ];

  home.sessionVariables = {
    SOPS_AGE_SSH_PRIVATE_KEY_FILE = "/etc/ssh/ssh_host_ed25519_key";
  };

  systemd.user.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

  wayland.windowManager.river = {
    enable = true;
    systemd.enable = false;
    extraConfig = builtins.readFile ./river/init;
  };

  xdg.configFile."uwsm/env-river".text = ''
    export WLR_NO_HARDWARE_CURSORS=1
    export WLR_RENDERER=gles2

    monitor_connected=0
    for status in /sys/class/drm/*/status; do
        [ -r "$status" ] || continue
        read -r state < "$status"
        if [ "$state" = connected ]; then
            monitor_connected=1
            break
        fi
    done

    if [ "$monitor_connected" -eq 0 ]; then
        export WLR_BACKENDS=headless,libinput
        export WLR_LIBINPUT_NO_DEVICES=1
        export WLR_HEADLESS_OUTPUTS=1
    fi
  '';

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

  programs.git = {
    settings = {
      user = {
        email = "andy.s.bolton@gmail.com";
      };
    };
  };

  services.swayidle = {
    enable = true;
    systemdTargets = [ "graphical-session.target" ];
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
        file_manager = "${pkgs.thunar}/bin/thunar";
      };
    };
  };
}
