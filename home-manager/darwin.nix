{ pkgs, ... }: {
  # imports = [ ./shared.nix ./modules/firefox.nix ./modules/lan-mouse.nix ];
  imports = [ ./shared.nix ];

  targets.darwin.copyApps.enable = true;

  home.homeDirectory = "/Users/andybolton";

  home.packages = with pkgs; [ azure-cli karabiner-elements skhd teams ];
}
