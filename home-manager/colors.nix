colors: rec {
  # name -> base16 hex (no prefix)
  palette = {
    # Neutrals (dark -> light for dark schemes)
    DARKEST_BACKGROUND = colors.base11;
    DARKER_BACKGROUND = colors.base10;
    BACKGROUND = colors.base00;
    LIGHTER_BACKGROUND = colors.base01;
    SELECTION = colors.base02;
    COMMENT = colors.base03;
    DARK_FOREGROUND = colors.base04;
    FOREGROUND = colors.base05;
    LIGHT_FOREGROUND = colors.base06;
    LIGHTEST_FOREGROUND = colors.base07;

    # Accents
    BLUE = colors.base0D;
    CYAN = colors.base0C;
    MAGENTA = colors.base0E;
    GREEN = colors.base0B;
    RED = colors.base08;
    YELLOW = colors.base0A;
    ORANGE = colors.base09;
    BROWN = colors.base0F;

    BRIGHT_RED = colors.base12;
    BRIGHT_YELLOW = colors.base13;
    BRIGHT_GREEN = colors.base14;
    BRIGHT_CYAN = colors.base15;
    BRIGHT_BLUE = colors.base16;
    BRIGHT_MAGENTA = colors.base17;

    WHITE = "ffffff";
    BLACK = "000000";
  };

  fmt = rec {
    literal = hex: "0x${hex}";

    argbAt = alpha: hex: "0x${alpha}${hex}";
    argb = argbAt "ff";

    rgbaAt = alpha: hex: "0x${hex}${alpha}";
    rgba = rgbaAt "ff";

    css = hex: "#${hex}";
    cssAt = alpha: hex: "#${hex}${alpha}";
  };

  roles = with palette; {
    DESKTOP = DARKEST_BACKGROUND;
    SURFACE = LIGHTER_BACKGROUND;
    EDGE = COMMENT;
    TEXT = FOREGROUND;
    TEXT_ALT = DARK_FOREGROUND;
    FOCUS = BLUE;
    UNFOCUSED = COMMENT;
    FILL = COMMENT;
    TRACK = SELECTION;
    TOGGLE_ON = MAGENTA;
    TOGGLE_OFF = BLUE;
    WARN = YELLOW;
    ATTENTION = ORANGE;
    ERROR = RED;
  };

  css = builtins.mapAttrs (_: fmt.css) (palette // roles);
  argb = builtins.mapAttrs (_: fmt.argb) (palette // roles);
  rgba = builtins.mapAttrs (_: fmt.rgba) (palette // roles);
  literal = builtins.mapAttrs (_: fmt.literal) (palette // roles);
}
