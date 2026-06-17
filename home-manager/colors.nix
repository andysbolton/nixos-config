colors:
let
  # name -> base16 hex (no prefix)
  raw = {
    # Backgrounds (darkest -> lighter)
    BASE = colors.base00;
    SURFACE = colors.base01;
    OVERLAY = colors.base03;

    # Text
    TEXT = colors.base07;
    SUBTEXT = colors.base04;

    # Accents
    BLUE = colors.base0D;
    CYAN = colors.base0C;
    TEAL = colors.base0C;
    MAGENTA = colors.base0E;
    GREEN = colors.base0B;
    RED = colors.base08;
    MAROON = colors.base0F;
    YELLOW = colors.base0A;
    ORANGE = colors.base09;
  };
in
(builtins.mapAttrs (_: hex: "0xff${hex}") raw)
// {
  # Utility (carry their own alpha)
  WHITE = "0xffffffff";
  TRANSPARENT = "0x00000000";
  HIGHLIGHT = "0x40ffffff";

  # #RRGGBB variants (no alpha).
  hex = builtins.mapAttrs (_: hex: "#${hex}") raw;
}
