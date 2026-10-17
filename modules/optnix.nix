{
  config,
  lib,
  options,
  pkgs,
  inputs,
  ...
}:
let
  optnixLib = inputs.optnix.mkLib pkgs;
  host = config.networking.hostName;
  flakeAttr =
    if pkgs.stdenv.isDarwin then
      "darwinConfigurations.${host}-darwin"
    else
      "nixosConfigurations.${host}";
  user = lib.head (lib.attrNames config.home-manager.users);
  inherit (config.home-manager.users.${user}) repoPath;

  flakeParts = inputs.flake-parts.lib.evalFlakeModule {
    inputs = {
      self = {
        outPath = "/dummy";
        inputs = { };
        outputs = { };
      };
      inherit (inputs) nixpkgs;
    };
  } { imports = builtins.attrValues inputs.flake-parts.flakeModules; };
in
{
  programs.optnix = {
    enable = true;
    package = pkgs.optnix;
    settings = {
      min_score = 1;
      debounce_time = 25;
      formatter_cmd = "nixfmt";
      split_ratio = 50;
      default_scope = "system";
      scopes = {
        system = {
          description = "System configuration for ${host}";
          options-list-file = optnixLib.mkOptionsList { inherit options; };
          evaluator = "nix eval ${repoPath}#${flakeAttr}.config.{{ .Option }}";
        };
        home-manager = {
          description = "Home Manager configuration for ${user}";
          options-list-file = optnixLib.mkOptionsList {
            inherit (options.home-manager.users.valueMeta.attrs.${user}.configuration) options;
            transform = o: o // { name = lib.removePrefix "home-manager.users.${user}." o.name; };
          };
          evaluator = "nix eval ${repoPath}#${flakeAttr}.config.home-manager.users.${user}.{{ .Option }}";
        };
        flake-parts = {
          description = "flake-parts options, including all bundled flake modules";
          options-list-file = optnixLib.mkOptionsList { inherit (flakeParts) options; };
        };
      };
    };
  };
}
