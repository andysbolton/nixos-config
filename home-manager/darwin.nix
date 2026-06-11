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
    if [ -f "$HOME/.config/karabiner.edn" ] && [ -f "$HOME/.config/karabiner/karabiner.json" ]; then
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

  home.file.".ssh/authorized_keys".text = ''
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAAGFGipKjoh/k9IHbfE00n4p5rnMMvsYNMS/Pbx3IE6SgoGSEPSFOxSiNsX7thhyT55fkDoQPaMr+0hGwaz+qeYpbInWfsZLjZOn5iqMgmqCPX5khe2UW+J9dPlAj5eCv2OCzNjbevnFU1MOlw1X26BbzdFS1VOd3OKmS72jEYOvQK7C/ciAj/ytlh+9NwJFcaUugXWJShhi6XMzfPWTDSTwcFlKfOH4n5uyRj7qi1ZGg8w9qnaSSIhaACgOGRXmfDoaVBCZx1fjeBYL9SeZMiIeCy3i2CPiUuKuVebP3p7DbavWq2055NSLQUK5MKfFeFJUHCgYtMOtckcv5SMR5 andy-rsa
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK3wN9/LQcWF0pun3XaCnRfNnIiMbJlCxG2tZl3n9I3c andy-ed25519
  '';

  launchd.agents.lan-mouse.config = {
    StandardOutPath = "/tmp/lan-mouse.log";
    StandardErrorPath = "/tmp/lan-mouse.err.log";
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
