let
  flake = builtins.getFlake "git+file:///home/andy/nixos-config";
  os = flake.nixosConfigurations.portable;
in
{
  inherit flake os;
  lib = os.lib;
  pkgs = os.pkgs;
  hm = os.config.home-manager.users.andy;
}
