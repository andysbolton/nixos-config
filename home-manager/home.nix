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
  imports = [ ./modules/lan-mouse.nix ./modules/waybar/waybar.nix ];
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

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    rsync
    xfce.thunar

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    (pkgs.writeShellScriptBin "firefox-vpn" ''
      SUDO_ASKPASS=${askPass}/bin/ask-pass sudo -A ip netns exec vpn sudo -u $(whoami) ${pkgs.firefox}/bin/firefox "$@"
    '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
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
      pkgs.dotnet-sdk
      pkgs.fennel-ls
      pkgs.fnlfmt
      pkgs.nodejs_24
      pkgs.lua-language-server
      pkgs.stylua
    ];
  };

  programs.firefox = {
    enable = true;

    profiles = {
      home = {
        name = "home";
        isDefault = true;
        extensions = { force = true; };
        # I'm having trouble using nur.repos.rycee.firefox-addons and installing unfree extensions.
        # extensions = {
        #   force = true;
        #   packages = with inputs.firefox-addons.packages."x86_64-linux"; [
        #     grammarly
        #     onepassword-password-manager
        #     privacy-badger
        #     refined-github
        #     ublock-origin
        #     vimium
        #   ];
        # };
      };
    };

    policies = {
      AppAutoUpdate = false;
      Cookies = { Behavior = "reject-tracker-and-partition-foreign"; };
      DisablePocket = true;
      DisableSystemAddonUpdate = true;
      DisableTelemetry = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptominig = true;
        Fingerpriting = true;
        EmailTracking = true;
      };
      FirefoxSuggest = {
        SponsoredSuggestions = false;
        ImproveSuggest = false;
      };
      Homepage = { StartPage = "none"; };
      ManualAppUpdateOnly = true;
      NetworkPrediction = false;
      PopupBlocking = { Default = true; };
      PostQuantumKeyAgreementEnabled = true;
      SkipTermsOfUse = true;
    };
  };

  stylix.targets.firefox.profileNames = [ "home" ];
  stylix.targets.firefox.colorTheme.enable = true;

  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 0;
        follow = "mouse";

        width = 800;
        height = 300;
        origin = "bottom-center";

        gap_size = 0;
        sort = "yes";

        font = lib.mkForce "Roboto 14";
        line_height = 0;

        markup = "full";
        format = ''
          <b>%s</b>
          %a

          %b'';
        alignment = "left";
        vertical_alignment = "right";
        show_age_threshold = 60;

        show_indicators = "yes";

        enable_recursive_icon_lookup = true;
        icon_position = "left";
        min_icon_size = 32;
        max_icon_size = 128;
      };

      urgency_low = { timeout = 5; };

      urgency_normal = { timeout = 10; };

      urgency_critical = { timeout = 0; };
    };
  };

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

  # swayidle -w timeout 1740 "dunstify --urgency=normal 'Locking session in 1 minute'" \
  #     timeout 1800 "wlopm --off '*'" resume "wlopm --on '*'" &
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

  # programs.lan-mouse = {
  #   enable = true;
  #   systemd = true;
  #   # package = inputs.lan-mouse.packages.${pkgs.stdenv.hostPlatform.system}.default
  #   # Optional configuration in nix syntax, see config.toml for available options
  #   settings = let
  #     # we can't use any ${pkgs} proper path,
  #     # because it also runs commands on the remote machine
  #     shareClipboard = dest:
  #       "wl-paste --no-newline | ssh ${dest} -i .ssh/id_home_nokey env WAYLAND_DISPLAY='wayland-1' wl-copy";
  #   in {
  #     release_bind = [ "KeyA" "KeyS" "KeyD" "KeyF" ];
  #     port = 4242;
  #     frontend = "cli";
  #     # right = {
  #     #   hostname = "crom";
  #     #   activate_on_startup = true;
  #     #   enter_hook = shareClipboard "crom";
  #     #   ips = [ "192.168.1.2" ];
  #     # };
  #     left = {
  #       hostname = "work";
  #       activate_on_startup = true;
  #       # enter_hook = shareClipboard "fw";
  #       # ips = [ "192.168.1.3" ];
  #     };
  #   };
  # };
  #
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
