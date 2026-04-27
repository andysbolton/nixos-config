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

  programs.fish = {
    enable = true;
    package = pkgs-unstable.fish;
  };

  environment.shells = [ pkgs-unstable.fish ];

  documentation.man.enable = true;

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
      "bot-framework-emulator"
      "microsoft-teams"
    ];
  };

  fonts.packages = with pkgs; [ nerd-fonts.caskaydia-cove ];

  services.karabiner-elements = {
    enable = true;
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
        top_padding 13 \
        bottom_padding 13 \
        left_padding 13 \
        right_padding 13 \
        window_gap 13 \
        layout bsp \
        mouse_modifier fn \
        mouse_action1 move \
        mouse_action2 resize \
        mouse_drop_action swap

      yabai -m rule --add app="^System Settings$" manage=off
      yabai -m rule --add app="^Microsoft Teams$" display=1 space=1
      yabai -m rule --add app="^Discord$" display=1 space=2
      yabai -m rule --add app="^GatherV2$" display=1 space=3
      yabai -m rule --add app="^Proton VPN$" display=1 space=7

      yabai -m signal --add event=window_created app="^WezTerm$" action="yabai -m window --focus $${YABAI_WINDOW_ID}"

      # Ensure 7 spaces exist on each display.
      for display in $(yabai -m query --displays | jq '.[].index'); do
        count=$(yabai -m query --spaces --display "$display" | jq '[.[] | select(."is-native-fullscreen" == false)] | length')
        while [ "$count" -lt 6 ]; do
          yabai -m display --focus "$display"
          yabai -m space --create
          count=$((count + 1))
        done
      done

      yabai -m rule --apply
      sketchybar --reload
    '';
  };

  system.stateVersion = 6;
}
