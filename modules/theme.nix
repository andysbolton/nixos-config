{ config, lib, pkgs, ... }:
{
  options.palette = lib.mkOption {
    type = lib.types.attrs;
    default = import ../home-manager/colors.nix config.lib.stylix.colors;
    description = "Color palette derived from the active base16 scheme.";
  };

  config.stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-moon.yaml";
}
