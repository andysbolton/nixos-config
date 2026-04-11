{
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
{
  networking.hostName = "work";

  users.users.andybolton = {
    home = "/Users/andybolton";
  };

  system.primaryUser = "andybolton";

  nix.settings = {
    experimental-features = [
      "flakes"
      "nix-command"
    ];
    trusted-users = [ "andybolton" ];
  };

  programs.fish.enable = true;

  environment.shells = with pkgs; [ fish ];

  homebrew = {
    enable = true;
    onActivation = {
      # "zap" removes manually installed brews and casks
      cleanup = "zap";
      autoUpdate = false;
      upgrade = false;
    };
    taps = [ "koekeishiya/formulae" ];
    brews = [
      "tfenv"
      "koekeishiya/formulae/skhd"
    ];
    casks = [
      "microsoft-teams"
    ];
  };

  fonts.packages = with pkgs; [ nerd-fonts.caskaydia-cove ];

  services.karabiner-elements = {
    enable = false;
    package = pkgs.karabiner-elements.overrideAttrs (old: {
      version = "14.13.0";

      src = pkgs.fetchurl {
        inherit (old.src) url;
        hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
      };

      dontFixup = true;
    });
  };

  system.defaults = {
    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };

    dock = {
      autohide = true;
      show-recents = false;
      tilesize = 40;
      mru-spaces = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };

    menuExtraClock = {
      Show24Hour = true;
      ShowDate = 1;
      ShowDayOfMonth = true;
      ShowDayOfWeek = true;
    };

    screencapture.location = "/Users/andybolton/Desktop";
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  services.yabai = {
    enable = true;
    enableScriptingAddition = true;
    package = pkgs-unstable.yabai;
    extraConfig = ''
      yabai -m config \
          external_bar all:40:0 \
          mouse_follows_focus off \
          focus_follows_mouse off \
          display_arrangement_order default \
          window_origin_display default \
          window_placement second_child \
          window_insertion_point focused \
          window_zoom_persist on \
          window_shadow on \
          window_animation_duration 0.0 \
          window_animation_easing ease_out_circ \
          window_opacity_duration 0.0 \
          active_window_opacity 1.0 \
          normal_window_opacity 0.90 \
          window_opacity off \
          insert_feedback_color 0xffd75f5f \
          split_ratio 0.50 \
          split_type auto \
          auto_balance off \
          top_padding 12 \
          bottom_padding 12 \
          left_padding 12 \
          right_padding 12 \
          window_gap 09 \
          layout bsp \
          mouse_modifier fn \
          mouse_action1 move \
          mouse_action2 resize \
          mouse_drop_action swap

      yabai -m rule --add app="^System Settings$" manage=off

      for display in $(yabai -m query --displays | jq '.[].index'); do
          count=$(yabai -m query --spaces --display "$display" | jq '[.[] | select(."is-native-fullscreen" == false)] | length')
          while [ "$count" -lt 6 ]; do
              yabai -m display --focus "$display"
              yabai -m space --create
              count=$((count + 1))
          done
      done
    '';
  };

  # 2. Fix the scripting addition daemon (sudo)
  system.stateVersion = 6;
}
