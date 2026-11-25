{ config, lib, ... }:
{
  flake.modules.homeManager.fleet-ssh = {
    programs.ssh.settings = lib.mapAttrs (
      name: device:
      let
        isRouter = device.type == "router";
      in
      {
        hostname = if isRouter then "${name}.tail4b1b78.ts.net" else device.ip;
        proxyjump = if isRouter then "none" else "router";
      }
    ) config.fleet.devices;
  };
}
