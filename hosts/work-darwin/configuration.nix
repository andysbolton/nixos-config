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
    ];
    casks = [
      "bot-framework-emulator"
      "microsoft-teams"
    ];
  };

  fonts.packages = with pkgs; [ nerd-fonts.caskaydia-cove ];

  services = {
    skhd = {
      enable = true;
      skhdConfig = ''
        # focus window
        ctrl + shift - h : yabai -m window --focus west  || yabai -m display --focus west
        ctrl + shift - j : yabai -m window --focus south || yabai -m display --focus south
        ctrl + shift - k : yabai -m window --focus north || yabai -m display --focus north
        ctrl + shift - l : yabai -m window --focus east  || yabai -m display --focus east

        # focus space
        cmd - 1 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[0].index // empty'); test -n "$i"; and yabai -m space --focus "$i"
        cmd - 2 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[1].index // empty'); test -n "$i"; and yabai -m space --focus "$i"
        cmd - 3 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[2].index // empty'); test -n "$i"; and yabai -m space --focus "$i"
        cmd - 4 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[3].index // empty'); test -n "$i"; and yabai -m space --focus "$i"
        cmd - 5 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[4].index // empty'); test -n "$i"; and yabai -m space --focus "$i"
        cmd - 6 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[5].index // empty'); test -n "$i"; and yabai -m space --focus "$i"
        cmd - 7 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[6].index // empty'); test -n "$i"; and yabai -m space --focus "$i"
        cmd - 8 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[7].index // empty'); test -n "$i"; and yabai -m space --focus "$i"
        cmd - 9 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[8].index // empty'); test -n "$i"; and yabai -m space --focus "$i"

        # move to space
        shift + cmd - 1 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[0].index // empty'); test -n "$i"; and yabai -m window --space "$i"; and yabai -m space --focus "$i"
        shift + cmd - 2 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[1].index // empty'); test -n "$i"; and yabai -m window --space "$i"; and yabai -m space --focus "$i"
        shift + cmd - 3 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[2].index // empty'); test -n "$i"; and yabai -m window --space "$i"; and yabai -m space --focus "$i"
        shift + cmd - 4 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[3].index // empty'); test -n "$i"; and yabai -m window --space "$i"; and yabai -m space --focus "$i"
        shift + cmd - 5 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[4].index // empty'); test -n "$i"; and yabai -m window --space "$i"; and yabai -m space --focus "$i"
        shift + cmd - 6 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[5].index // empty'); test -n "$i"; and yabai -m window --space "$i"; and yabai -m space --focus "$i"
        shift + cmd - 7 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[6].index // empty'); test -n "$i"; and yabai -m window --space "$i"; and yabai -m space --focus "$i"
        shift + cmd - 8 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[7].index // empty'); test -n "$i"; and yabai -m window --space "$i"; and yabai -m space --focus "$i"
        shift + cmd - 9 : set i (yabai -m query --spaces --display | jq -r 'map(select(."is-native-fullscreen" == false))[8].index // empty'); test -n "$i"; and yabai -m window --space "$i"; and yabai -m space --focus "$i"

        # swap managed window
        ctrl + shift + alt - h : set id (yabai -m query --windows --window | jq '.id'); yabai -m window --swap west || { yabai -m window --display west && yabai -m window --focus "$id" }
        ctrl + shift + alt - j : set id (yabai -m query --windows --window | jq '.id'); yabai -m window --swap south || { yabai -m window --display south && yabai -m window --focus "$id" }
        ctrl + shift + alt - k : set id (yabai -m query --windows --window | jq '.id'); yabai -m window --swap north|| { yabai -m window --display north && yabai -m window --focus "$id" }
        ctrl + shift + alt - l : set id (yabai -m query --windows --window | jq '.id'); yabai -m window --swap east || { yabai -m window --display east && yabai -m window --focus "$id" }

        # balance size of windows
        shift + alt - 0 : yabai -m space --balance

        shift + ctrl - o : yabai -m window --focus recent 
        shift + ctrl - i : yabai -m window --focus next

        # fast focus desktop
        cmd + alt - 1 : yabai -m space --focus 1
        cmd + alt - 2 : yabai -m space --focus 2
        cmd + alt - 3 : yabai -m space --focus 3

        # expand window to the left OR shrink from the right
        alt + shift - h : yabai -m window --resize left:-20:0 || yabai -m window --resize right:-20:0
        # expand window down OR shrink from the top
        alt + shift - j : yabai -m window --resize bottom:0:20 || yabai -m window --resize top:0:20
        # expand window up OR shrink from the bottom
        alt + shift - k : yabai -m window --resize top:0:-20 || yabai -m window --resize bottom:0:-20
        # expand window to the right OR shrink from the left
        alt + shift - l : yabai -m window --resize right:20:0 || yabai -m window --resize left:20:0

        cmd - return : "$HOME/Applications/Home Manager Apps/WezTerm.app/wezterm-gui" start --always-new-process &

        cmd - t: wezterm-launch.sh 
      '';
    };

    karabiner-elements = {
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

    yabai = {
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

        yabai -m signal --add label="float_wezterm" event=window_created app="^WezTerm\$" action='
            title=$(yabai -m query --windows --window $YABAI_WINDOW_ID | jq -r .title)
            echo "title is $title" >> /tmp/title
            if [ "$title" = "launch.sh" ]; then
                yabai -m window $YABAI_WINDOW_ID --toggle float
                yabai -m window $YABAI_WINDOW_ID --grid 4:4:1:1:2:2
            fi
            yabai -m window $YABAI_WINDOW_ID --focus
        '

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
      '';
    };
  };

  launchd.user.agents.skhd.serviceConfig = {
    StandardOutPath = "/tmp/skhd.log";
    StandardErrorPath = "/tmp/skhd.err.log";
  };

  launchd.user.agents.yabai.serviceConfig = {
    StandardOutPath = "/tmp/yabai.log";
    StandardErrorPath = "/tmp/yabai.err.log";
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

  system.stateVersion = 6;
}
