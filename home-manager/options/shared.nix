{ config, lib, ... }:
{
  options = {
    repoName = lib.mkOption {
      type = lib.types.str;
      default = "nixos-config";
      description = "Repo name.";
    };
    repoPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/${config.repoName}";
      description = "Repo base path.";
    };
    dotfilesPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.repoPath}/home-manager/dotfiles";
      description = "Base path for shared dotfiles.";
    };
  };
}
