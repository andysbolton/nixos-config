{ config, lib, ... }:
{
  options = {
    repoName = lib.mkOption {
      type = lib.types.str;
      default = "nixos-config";
      description = "Repo name.";
    };
    dotfilesPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/${config.repoName}/home-manager/dotfiles";
      description = "Base path for shared dotfiles";
    };
  };
}
