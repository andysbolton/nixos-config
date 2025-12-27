{ config, lib, pkgs, inputs, ... }:
let
  # https://github.com/davatorium/rofi/issues/584#issuecomment-384555551
  askPass = (pkgs.writeShellScriptBin "ask-pass" ''
    rofi -dmenu \
        -password \
        -no-fixed-num-lines \
        -p "$(printf "$1" | sed s/://)"
  '');
in {
  imports = [
    ./modules/dunst.nix
    ./modules/firefox.nix
    ./modules/lan-mouse.nix
    ./modules/waybar/waybar.nix
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "andy";
  home.homeDirectory = "/home/andy";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    lua
    lua52Packages.fennel
    rsync
    xfce.thunar
    roswell
    rlwrap
    (sbcl.withPackages (ps: [ ps.swank ]))
    tcpdump
    traceroute
    whois

    (pkgs.writeShellScriptBin "firefox-vpn" ''
      SUDO_ASKPASS=${askPass}/bin/ask-pass \
        sudo -A ip netns exec \
          vpn sudo -u $(whoami) ${pkgs.firefox}/bin/firefox"$@"
    '')
  ];

  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/andy/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  stylix.targets.neovim.enable = false;
  stylix.targets.waybar.enable = false;

  programs.neovim = {
    enable = true;
    extraPackages = [
      pkgs.cargo
      pkgs.clang-tools
      pkgs.dotnet-sdk
      pkgs.fennel-ls
      pkgs.fnlfmt
      pkgs.nodejs_24
      pkgs.lua-language-server
      pkgs.stylua
    ];
  };

  stylix.targets.firefox.profileNames = [ "home" ];
  stylix.targets.firefox.colorTheme.enable = true;

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
  };

  programs.btop.enable = true;

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
      # workaround for
      # https://github.com/nix-community/home-manager/issues/632
      program_options = { file_manager = "${pkgs.xfce.thunar}/bin/thunar"; };
    };
  };
}
