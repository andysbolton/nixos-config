{ pkgs, scripts }:

''
  layout_generator=rivertile
  layout_cmd=${pkgs.river-classic}/bin/rivertile

  riverctl map normal Super Return spawn "uwsm app -- wezterm"
  riverctl map normal Alt+Shift F spawn "killall .firefox-wrapped || uwsm app -- firefox"
  riverctl map normal Alt+Shift+Control F spawn "killall .firefox-wrapped || uwsm app -- firefox-vpn"
  riverctl map normal Super N spawn "uwsm app -- ${pkgs.foot}/bin/foot --app-id=nixpkgs-search ${scripts.search-nix-pkgs}/bin/search-nix-pkgs"
  riverctl map normal Super T spawn "uwsm app -- ${pkgs.foot}/bin/foot --app-id=nixos-launcher ${scripts.nixos-launcher}/bin/nixos-launcher"
  riverctl map normal Super S spawn "uwsm app -- ${pkgs.grim}/bin/grim -g \"\$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy"

  riverctl map normal Super Q close
  riverctl map normal Control+Shift E spawn "uwsm stop"

  riverctl input pointer-1133-45082-MX_Anywhere_2S_Mouse middle-emulation enabled

  riverctl map normal Control+Shift+Super R spawn '${pkgs.killall}/bin/killall -SIGUSR2 .waybar-wrapped || (uwsm app -- ${pkgs.waybar}/bin/waybar & ${pkgs.dunst}/bin/dunstify "Reloaded waybar.")'

  riverctl map normal Control+Shift K focus-view up
  riverctl map normal Control+Shift J focus-view down
  riverctl map normal Control+Shift H focus-view left
  riverctl map normal Control+Shift L focus-view right

  riverctl map normal Control+Shift bracketright swap next
  riverctl map normal Control+Shift bracketleft swap previous

  riverctl map normal Control+Shift+Alt K swap up
  riverctl map normal Control+Shift+Alt J swap down
  riverctl map normal Control+Shift+Alt H swap left
  riverctl map normal Control+Shift+Alt L swap right

  riverctl map normal Control Period focus-output next
  riverctl map normal Control Comma focus-output previous
  riverctl map normal Control+Shift Period send-to-output next
  riverctl map normal Control+Shift Comma send-to-output previous

  riverctl map normal Control Return zoom
  riverctl map normal Control+Shift MINUS send-layout-cmd "$layout_generator" "main-ratio -0.05"
  riverctl map normal Control+Shift EQUAL send-layout-cmd "$layout_generator" "main-ratio +0.05"

  riverctl map normal Control+Alt H move left 100
  riverctl map normal Control+Alt J move down 100
  riverctl map normal Control+Alt K move up 100
  riverctl map normal Control+Alt L move right 100

  riverctl map normal Super+Alt+Control H snap left
  riverctl map normal Super+Alt+Control J snap down
  riverctl map normal Super+Alt+Control K snap up
  riverctl map normal Super+Alt+Control L snap right

  riverctl map normal Super+Alt+Shift H resize horizontal 100
  riverctl map normal Super+Alt+Shift J resize vertical 100
  riverctl map normal Super+Alt+Shift K resize vertical -100
  riverctl map normal Super+Alt+Shift L resize horizontal -100

  riverctl map-pointer normal Super BTN_LEFT move-view
  riverctl map-pointer normal Super BTN_RIGHT resize-view
  riverctl map-pointer normal Super BTN_MIDDLE toggle-float

  # --- TAGS (1-9) ---
  for i in $(seq 1 9); do
      tags=$((1 << (i - 1)))
      riverctl map normal Super "$i" set-focused-tags $tags
      riverctl map normal Super+Shift "$i" spawn "riverctl set-view-tags $tags && riverctl set-focused-tags $tags"
      riverctl map normal Super+Control "$i" toggle-focused-tags $tags
      riverctl map normal Super+Shift+Control "$i" toggle-view-tags $tags
  done

  bluetooth_tag=$((1 << 9))
  riverctl rule-add -title "Bluetooth Devices" tags $bluetooth_tag
  riverctl map normal Super B set-focused-tags $bluetooth_tag

  vesktop_tag=$((1 << 8))
  riverctl rule-add -title "Discord" tags $vesktop_tag
  riverctl map normal Super D set-focused-tags $vesktop_tag

  games_tag=$((1 << 7))
  riverctl rule-add -app-id "*steam*" tags $games_tag
  riverctl map normal Super G set-focused-tags $games_tag

  pass_tag=$((1 << 6))
  riverctl rule-add -app-id "1password" tags $pass_tag
  riverctl map normal Super G set-focused-tags $pass_tag

  # All tags/Global
  all_tags=$(((1 << 9) - 1))
  riverctl map normal Super 0 set-focused-tags $all_tags
  riverctl map normal Super+Shift 0 set-view-tags $all_tags

  riverctl map normal Super Space toggle-float
  riverctl map normal Super F toggle-fullscreen

  # Layout Orientation
  riverctl map normal Super Up send-layout-cmd "$layout_generator" "main-location top"
  riverctl map normal Super Right send-layout-cmd "$layout_generator" "main-location right"
  riverctl map normal Super Down send-layout-cmd "$layout_generator" "main-location bottom"
  riverctl map normal Super Left send-layout-cmd "$layout_generator" "main-location left"

  # Passthrough Mode.
  riverctl declare-mode passthrough
  riverctl map normal Super F11 enter-mode passthrough
  riverctl map passthrough Super+Shift F11 enter-mode normal

  for mode in normal locked; do
      riverctl map $mode None XF86Eject spawn '${pkgs.util-linux}/bin/eject -T'
      riverctl map $mode None XF86AudioRaiseVolume spawn '${pkgs.pamixer}/bin/pamixer -i 5'
      riverctl map $mode None XF86AudioLowerVolume spawn '${pkgs.pamixer}/bin/pamixer -d 5'
      riverctl map $mode None XF86AudioMute spawn '${pkgs.pamixer}/bin/pamixer --toggle-mute'
      riverctl map $mode None XF86AudioMedia spawn '${pkgs.playerctl}/bin/playerctl play-pause'
      riverctl map $mode None XF86AudioPlay spawn '${pkgs.playerctl}/bin/playerctl play-pause'
      riverctl map $mode None XF86AudioPrev spawn '${pkgs.playerctl}/bin/playerctl previous'
      riverctl map $mode None XF86AudioNext spawn '${pkgs.playerctl}/bin/playerctl next'
      riverctl map $mode None XF86MonBrightnessUp spawn '${pkgs.brightnessctl}/bin/brightnessctl set +5%'
      riverctl map $mode None XF86MonBrightnessDown spawn '${pkgs.brightnessctl}/bin/brightnessctl set 5%-'
  done

  riverctl background-color 0x1a1b26
  riverctl border-color-focused 0x93a1a1
  riverctl border-color-unfocused 0x586e75
  riverctl border-width 3
  riverctl set-repeat 50 300

  riverctl rule-add -app-id 'float*' -title 'foo' float
  riverctl rule-add -app-id "bar" csd

  # Firefox draws CSD by default; force SSD so river draws its border.
  riverctl rule-add -app-id "firefox" ssd

  riverctl rule-add -app-id "nixpkgs-search" float
  riverctl rule-add -app-id "nixpkgs-search" dimensions 1280 800

  riverctl default-layout "$layout_generator"
  $layout_cmd -view-padding 18 -outer-padding 18 &

  # It makes sure WAYLAND_DISPLAY is shared and unblocks graphical-session.target.
  uwsm finalize

  # Using 'uwsm app --' ensures these stay alive correctly and die on logout.
  uwsm app -- wezterm &
  uwsm app -- ${pkgs.blueman}/bin/blueman-applet &
  uwsm app -- ${pkgs.blueman}/bin/blueman-manager &
  uwsm app -- vesktop.desktop &
  uwsm app -- 1password &
  uwsm app -- steam -silent &
  uwsm app -- lxqt-policykit-agent &

  # Clipboard management
  uwsm app -- ${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist -db-path "$HOME"/.cache/cliphist/system-db store &
  uwsm app -- ${pkgs.wl-clipboard}/bin/wl-paste --primary --watch ${pkgs.cliphist}/bin/cliphist -db-path "$HOME"/.cache/cliphist/primary-db store &
''
