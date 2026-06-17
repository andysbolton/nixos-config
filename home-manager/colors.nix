# Sketchybar / jankyborders palette derived from the active Stylix base16
# scheme. Import with `config.lib.stylix.colors`; returns 0xAARRGGBB strings.
colors:
let
  opaque = hex: "0xff${hex}";
in
{
  # Backgrounds (darkest -> lighter)
  BASE = opaque colors.base00;
  SURFACE = opaque colors.base01;
  OVERLAY = opaque colors.base03;

  # Text
  TEXT = opaque colors.base07;
  SUBTEXT = opaque colors.base04;

  # Accents. base16 has a single cyan slot, so TEAL aliases CYAN.
  BLUE = opaque colors.base0D;
  CYAN = opaque colors.base0C;
  TEAL = opaque colors.base0C;
  MAGENTA = opaque colors.base0E;
  GREEN = opaque colors.base0B;
  RED = opaque colors.base08;
  MAROON = opaque colors.base0F;
  YELLOW = opaque colors.base0A;
  ORANGE = opaque colors.base09;

  # Utility
  WHITE = "0xffffffff";
  TRANSPARENT = "0x00000000";
  HIGHLIGHT = "0x40ffffff";
}
