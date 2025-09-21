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
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    askPass
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
  home.sessionVariables = { EDITOR = "nvim"; };

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

  programs.waybar = {
    enable = true;
    settings = builtins.fromJSON (builtins.readFile ./waybar/config.json);
    style = ./waybar/style.css;
    # This is failing at the moment with 'ConditionEnvironment=WAYLAND_DISPLAY was not met'. I'm going
    # to revisit it later, but for now I will start waybar from river's init script.
    # systemd = {
    #   enable = true;
    #   target = "river-session.target";
    # };
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
}
