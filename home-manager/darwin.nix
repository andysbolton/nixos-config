{ pkgs, pkgs-unstable, ... }:
{
  # imports = [ ./shared.nix ./modules/firefox.nix ./modules/lan-mouse.nix ];
  imports = [
    ./shared.nix
    ./modules/firefox.nix
  ];

  targets.darwin.copyApps.enable = true;
  targets.darwin.linkApps.enable = false;

  home.homeDirectory = "/Users/andybolton";

  home.packages = with pkgs; [
    azure-cli
    postgresql
    reattach-to-user-namespace
  ];

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

  home.file.".config/skhd/skhdrc".text = builtins.readFile ./skhd/skhdrc;

  programs.sketchybar = {
    enable = true;
    includeSystemPath = true;
    extraPackages = [
      pkgs.jq
      pkgs-unstable.yabai
    ];
    config = {
      source = ./sketchybar;
      recursive = true;
    };
  };
}
