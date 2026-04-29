{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  self,
  ...
}:
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
    choose.source = config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/choose";
    "karabiner/karabiner.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/karabiner/karabiner.json";
    "skhd/home-manager.skhdrc".source =
      config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/skhd/home-manager.skhdrc";
    sketchybar.source = config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/sketchybar";
  };

  home.packages = with pkgs; [
    (azure-cli.withExtensions [ azure-cli-extensions.resource-graph ])
    jira-cli-go
    maccy
    powershell
  ];

  home.sessionVariables = {
    BROWSER = "${pkgs.firefox}/Applications/Firefox.app/Contents/MacOS/firefox";
  };

  services.jankyborders = {
    enable = true;
    settings = {
      width = 9.0;
      blur_radius = 5.0;
      active_color = "0xff7aa2f7";
      inactive_color = "0xffcfc9c2";
    };
  };

  # TODO: Make this dependent on yabai
  programs.sketchybar = {
    enable = true;
    includeSystemPath = true;
    extraPackages = [
      pkgs-unstable.yabai
      pkgs.ifstat-legacy
      pkgs.jq
    ];
  };
}
