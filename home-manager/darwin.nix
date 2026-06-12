{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  self,
  osConfig,
  ...
}:
let
  sketchybarBottom = pkgs.callPackage ../pkgs/sketchybar-bottom.nix { inherit pkgs-unstable; };
in
{
  imports = [
    ./modules/firefox.nix
    ./options/work.nix
    ./shared.nix
  ];

  targets.darwin.copyApps.enable = true;
  targets.darwin.linkApps.enable = false;

  home.homeDirectory = "/Users/andybolton";

  xdg.configFile = {
    # This is likely redundant, let's remove it sometime.
    "karabiner.edn".source =
      config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/karabiner/karabiner.edn";
    "skhd/home-manager.skhdrc".source =
      config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/skhd/home-manager.skhdrc";
    sketchybar.source = config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/sketchybar";
    sketchybar-bottom.source = config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/sketchybar";
  };

  home.activation.runGoku = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    kbjson="$HOME/.config/karabiner/karabiner.json"
    if [ -f "$HOME/.config/karabiner.edn" ] && [ -f "$kbjson" ]; then
      # goku can't create profiles or set per-device options. Reconcile karabiner.json
      # to our canonical set: drop any profile that is not ours (e.g. the auto-created
      # "Default profile") and inject any of ours that are missing, so goku's
      # "profile must exist" check passes and the Logitech stays grabbed across the
      # lan-mouse work<->empty switch.
      ${pkgs.jq}/bin/jq --argjson want "$(cat ${./dotfiles/karabiner/profiles.json})" '
        ($want | map(.name)) as $names                                    # our canonical profile names
        | .profiles |= map(select(.name | IN($names[])))                  # drop profiles that are not ours
        | [.profiles[].name] as $have                                     # of ours, which already exist
        | .profiles += [ $want[] | select((.name | IN($have[])) | not) ]  # append the missing ones
      ' "$kbjson" | ${pkgs.moreutils}/bin/sponge "$kbjson"

      run ${pkgs.goku}/bin/goku
      run --quiet "${osConfig.services.karabiner-elements.package}/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli" --select-profile work
    fi
  '';

  home.packages = with pkgs; [
    _1password-cli
    _1password-gui
    (azure-cli.withExtensions [
      azure-cli-extensions.azure-devops
      azure-cli-extensions.durabletask
      azure-cli-extensions.resource-graph
    ])
    desktoppr
    gatherv2
    goku
    jira-cli-go
    maccy
    moonlight-qt
    powershell
    powershell-editor-services
    sketchybarBottom
  ];

  home.sessionPath = [
    "${config.home.homeDirectory}/Applications/Home Manager Apps/WezTerm.app"
  ];

  home.sessionVariables = {
    BROWSER = "${pkgs.firefox}/Applications/Firefox.app/Contents/MacOS/firefox";
  };

  launchd.agents.sketchybar-bottom = {
    enable = true;
    config = {
      Label = "org.nix-community.home.sketchybar-bottom";
      ProcessType = "Interactive";
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/sketchybar/sketchybar-bottom.out.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/sketchybar/sketchybar-bottom.err.log";
      Program = "${sketchybarBottom}/bin/sketchybar-bottom";
    };
  };

  services.jankyborders = {
    enable = true;
    settings = {
      width = 5.0;
      active_color = "0xff7dcfff";
      inactive_color = "0xff414868";
      hidpi = "on";
    };
  };

  programs.sketchybar = {
    enable = true;
    includeSystemPath = true;
    extraPackages = [
      pkgs-unstable.yabai
      pkgs.entr
      pkgs.ifstat-legacy
      pkgs.jq
    ];
  };

  programs.git = {
    settings = {
      user = {
        email = "andy.bolton@smartwyre.com";
      };
    };
  };
}
