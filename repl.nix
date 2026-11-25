let
  flake = builtins.getFlake (toString ./.);
  os = flake.nixosConfigurations.portable;
in
{
  inherit flake os;
  lib = os.lib;
  pkgs = os.pkgs;
  hm = os.config.home-manager.users.andy;
}
