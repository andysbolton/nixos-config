{ pkgs }:
{
  # Compile a single .fnl file to a .lua store file with the Fennel compiler.
  # Usage: home.file."...".source = (import ./lib/mk-fennel.nix { inherit pkgs; }).mkFennelLua "name.lua" ./path/to/src.fnl;
  mkFennelLua =
    name: src:
    pkgs.runCommand name { } ''
      ${pkgs.luaPackages.fennel}/bin/fennel --compile ${src} > $out
    '';
}
