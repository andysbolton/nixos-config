{ lib, ... }:
{
  options.monitors = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          scale = lib.mkOption {
            type = lib.types.nullOr lib.types.float;
            default = null;
          };
          rightOf = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "eDP-1";
            description = "Output to place this one to the right of.";
          };
        };
      }
    );
    default = { };
    description = "Per-output settings, keyed by Wayland output name.";
  };
}
