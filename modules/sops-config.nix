# .sops.yaml generated from the age public keys in the repo: each host's
# secrets file is encrypted for andy and that host.
{ lib, ... }:
let
  readKey = path: lib.trim (builtins.readFile path);
  hosts = builtins.filter (host: builtins.pathExists ../hosts/${host}/keys/age.pub) (
    builtins.attrNames (builtins.readDir ../hosts)
  );
  rules = {
    creation_rules = map (host: {
      path_regex = "secrets/${host}\\.yaml$";
      key_groups = [
        {
          age = [
            (readKey ../keys/andy.age)
            (readKey ../hosts/${host}/keys/age.pub)
          ];
        }
      ];
    }) hosts;
  };
in
{
  flake.modules.homeManager.sops-config =
    { config, pkgs, ... }:
    {
      home.file."${lib.removePrefix "${config.home.homeDirectory}/" config.repoPath}/.sops.yaml".source =
        (pkgs.formats.yaml { }).generate "sops-config.yaml"
          rules;
    };
}
