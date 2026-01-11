{ lib, ... }: {
  imports = (lib.lists.flatten [
    ./hardware.nix
    ./torrenting.nix
    ./steam.nix
    ./vpn.nix
    (lib.pipe ./arrs [
      builtins.readDir
      (lib.mapAttrsToList (name: _: ./arrs + "/${name}"))
    ])
  ]);
}
