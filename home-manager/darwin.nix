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
    "skhd/skhdrc".source = config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/skhd/skhdrc";
    sketchybar.source = config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/sketchybar";
    "yabai/jumplist.sh" = {
      source = pkgs.writeShellScript "yabai-jumplist" ''
        jumplist="/tmp/yabai-jumplist"

        case "$1" in
        back)
            current_window=$(yabai -m query --windows --window | jq '.id')
            echo "$current_window" >>"$jumplist"
            yabai -m space --focus recent
            ;;
        forward)
            if [ -s "$jumplist" ]; then
                next_window=$(tail -n 1 "$jumplist")
                sed -i "" "$d" "$jumplist" # Remove last line
                yabai -m window --focus "$next_window"
            fi
            ;;
        clear)
            # Clear the stack when a new manual action happens
            : >"$jumplist"
            ;;
        esac
      '';
    };
  };

  home.packages = with pkgs; [
    (azure-cli.withExtensions [ azure-cli-extensions.resource-graph ])
    choose-gui
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
