{ config, lib, ... }:
let
  me = config.me;
in
{
  options.me = lib.mkOption {
    type = lib.types.str;
    default = "andy";
  };

  config.flake.modules.nixos.me = {
    users.users.${me} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keyFiles = [
        ../keys/andy-ed25519.pub
      ];
      initialHashedPassword = "$y$j9T$cPhQ60emoTpQq2I30.bZR1$uVsrdUShDZItkDZHkX48r297JmlCWmIuIAxRkJqvNM1";
    };

    nix.settings.trusted-users = [ "@wheel" ];
  };
}
