{ config, lib, ... }:
{
  options.work = {
    email = lib.mkOption {
      type = lib.types.str;
      description = "Work email.";
    };
    company = lib.mkOption {
      type = lib.types.str;
      description = "Company name.";
    };
  };

  config =
    let
      localConfig = builtins.fromTOML (
        builtins.readFile "${config.home.homeDirectory}/${config.repoName}/home-manager/work.toml"
      );
    in
    {
      work.email = localConfig.email;
      work.company = localConfig.company;
    };
}
