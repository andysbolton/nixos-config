{ pkgs }:

rec {
  bookmarks = pkgs.writeShellApplication {
    name = "bookmarks.sh";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      perl
      sqlite
    ];
    bashOptions = [ ];
    text = builtins.readFile ../dotfiles/bin/bookmarks.sh;
  };

  nixos-launcher = pkgs.writeShellApplication {
    name = "nixos-launcher";
    runtimeInputs = [
      bookmarks
      pkgs.coreutils
      pkgs.fzf
    ];
    bashOptions = [ ];
    text = builtins.readFile ../dotfiles/bin/nixos_launcher.sh;
  };

  search-nix-pkgs = pkgs.writeShellApplication {
    name = "search-nix-pkgs";
    runtimeInputs = with pkgs; [
      coreutils
      fzf
      wl-clipboard
    ];
    text = builtins.readFile ../dotfiles/bin/search-nix-pkgs.sh;
  };
}
