{
  config,
  inputs,
  lib,
  ...
}:
let
  deploy-rs = inputs.deploy-rs;

  hosts = {
    router = config.fleet.router;
  }
  // config.fleet.nodes;

  mkHost =
    _: device:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ../../hosts/${device.type}/configuration.nix
        inputs.disko.nixosModules.disko
        { fleet.device = device; }
      ];
    };

  mkDeployNode =
    hostName: device:
    let
      nixos = inputs.self.nixosConfigurations.${hostName};
      system = nixos.pkgs.stdenv.hostPlatform.system;
    in
    {
      hostname = hostName;
      profiles.system = {
        user = "root";
        groups = [ device.type ];
        path = deploy-rs.lib.${system}.activate.nixos nixos;
      };
    };
in
{
  flake.nixosConfigurations = lib.mapAttrs mkHost hosts;
  flake.deploy.nodes = lib.mapAttrs mkDeployNode hosts;

  flake.checks = builtins.mapAttrs (
    system: deployLib: deployLib.deployChecks inputs.self.deploy
  ) deploy-rs.lib;
}
