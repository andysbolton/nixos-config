{ config, lib, pkgs, pkgs-unstable, self, ... }: {
  imports = [ ./shared.nix ./modules/firefox.nix ];

  targets.darwin.copyApps.enable = true;
  targets.darwin.linkApps.enable = false;

  home.homeDirectory = "/Users/andybolton";

  xdg.configFile = {
    "karabiner/karabiner.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.dotfilesPath}/karabiner/karabiner.json";
    "skhd/skhdrc".source =
      config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/skhd/skhdrc";
    sketchybar.source =
      config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/sketchybar";
  };

  home.packages = with pkgs; [
    (azure-cli.withExtensions [ azure-cli-extensions.resource-graph ])
    choose-gui
    powershell
  ];

  home.sessionVariables = { BROWSER = "${pkgs.firefox}/bin/firefox"; };

  services.jankyborders = {
    enable = true;
    settings = {
      blur_radius = 5.0;
      active_color = "0xffe1e3e4";
      inactive_color = "0xff494d64";
    };
  };

  # skhd is installed by brew in configuration.nix because it keeps getting flagged by SentinelOne
  launchd.agents.skhd = {
    enable = true;
    config = {
      ProgramArguments = [ "/opt/homebrew/bin/skhd" ];
      RunAtLoad = true;
      KeepAlive = true;
      SessionCreate = true;
      StandardOutPath = "/tmp/skhd.log";
      StandardErrorPath = "/tmp/skhd.err.log";
    };
  };

  programs.sketchybar = {
    enable = true;
    includeSystemPath = true;
    extraPackages = [ pkgs-unstable.yabai pkgs.ifstat-legacy pkgs.jq ];
  };
}
