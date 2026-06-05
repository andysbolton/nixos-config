{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.lan-mouse.homeManagerModules.default ];

  programs.lan-mouse = {
    enable = true;
    settings = {
      release_bind = [
        "KeyA"
        "KeyS"
        "KeyD"
        "KeyF"
      ];
      port = 4242;
      frontend = "cli";

      clients =
        if pkgs.stdenv.isDarwin then
          [
            {
              position = "left";
              hostname = "main.local";
              activate_on_startup = true;
              ips = [ ];
            }
          ]
        else
          [
            {
              position = "right";
              hostname = "work.local";
              activate_on_startup = true;
              ips = [ ];
            }
          ];
    };
  };
}
