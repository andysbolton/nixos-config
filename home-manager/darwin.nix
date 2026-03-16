{ pkgs, ... }: {
  # imports = [ ./shared.nix ./modules/firefox.nix ./modules/lan-mouse.nix ];
  imports = [ ./shared.nix ];

  home.homeDirectory = "/Users/andybolton";

  home.packages = with pkgs;
    [
      # darwin-specific packages here
    ];
}
