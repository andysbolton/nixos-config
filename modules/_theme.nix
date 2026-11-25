{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  # Each theme pairs a base16/24 scheme (Stylix and the colors.nix roles) with native ports for
  # apps whose own theme looks better than the generic base16 mapping. Without `nvim`, or with
  # fish = null, Stylix's own target themes that app.
  themes = {
    tokyonight-storm = {
      scheme = ../themes/tokyonight-storm.yaml;
      nvim = {
        plugin = "folke/tokyonight.nvim";
        colorscheme = "tokyonight-storm";
        lualine = "tokyonight-storm";
      };
      fish = "tokyonight_storm";
    };
    catppuccin-mocha = {
      scheme = "${pkgs.base16-schemes.src}/base24/catppuccin-mocha.yaml";
      nvim = {
        plugin = "catppuccin/nvim";
        name = "catppuccin";
        colorscheme = "catppuccin-mocha";
        lualine = "catppuccin-mocha";
      };
      fish = null;
    };
  };
  selected = themes.tokyonight-storm;
  colors = import ../home-manager/colors.nix config.lib.stylix.colors;
in
{
  options.theme = lib.mkOption {
    type = lib.types.submodule {
      freeformType = lib.types.attrsOf lib.types.anything;
      options.fontSize = lib.mkOption {
        type = lib.types.int;
        default = 13;
      };
    };
    description = "Color palette derived from the active base16 or 24 scheme, plus the active theme's native app settings.";
  };

  config = lib.mkMerge [
    {
      theme = colors // {
        wallpaper =
          pkgs.runCommand "wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; }
            "magick -size 3840x2400 radial-gradient:'${colors.css.DARKER_BACKGROUND}'-'${colors.css.DESKTOP}' -attenuate 0.4 +noise Gaussian $out";
        native = {
          inherit (selected) fish;
          nvim = selected.nvim or null;
        };
      };
      stylix.base16Scheme = selected.scheme;
      stylix.fonts = {
        monospace = {
          package = pkgs.nerd-fonts.caskaydia-cove;
          name = "CaskaydiaCove Nerd Font";
        };
        sansSerif = {
          package = pkgs.nerd-fonts.noto;
          name = "NotoSans Nerd Font";
        };
        serif = {
          package = pkgs.nerd-fonts.noto;
          name = "NotoSerif Nerd Font";
        };
        sizes = {
          applications = config.theme.fontSize;
          desktop = config.theme.fontSize;
          popups = config.theme.fontSize;
          terminal = config.theme.fontSize;
        };
      };
      fonts = {
        packages = [
          config.stylix.fonts.monospace.package
          config.stylix.fonts.sansSerif.package
          config.stylix.fonts.serif.package
          config.stylix.fonts.emoji.package
          pkgs.noto-fonts
          pkgs.noto-fonts-cjk-sans
          pkgs.nerd-fonts.symbols-only
        ];
      }
      # nix-darwin has no fontconfig options.
      // lib.optionalAttrs (options.fonts ? fontconfig) {
        enableDefaultPackages = false;
        fontconfig.defaultFonts = {
          monospace = [
            config.stylix.fonts.monospace.name
            config.stylix.fonts.emoji.name
          ];
          sansSerif = [
            config.stylix.fonts.sansSerif.name
            config.stylix.fonts.emoji.name
          ];
          serif = [
            config.stylix.fonts.serif.name
            config.stylix.fonts.emoji.name
          ];
          emoji = [ config.stylix.fonts.emoji.name ];
        };
      };
      home-manager.sharedModules = [
        {
          stylix.base16Scheme = config.stylix.base16Scheme;
          stylix.fonts = {
            inherit (config.stylix.fonts)
              monospace
              sansSerif
              serif
              sizes
              ;
          };
        }
      ];
    }
    # nix-darwin's Stylix has no cursor option.
    (lib.optionalAttrs (options.stylix ? cursor) {
      stylix.cursor = {
        name = "phinger-cursors-dark";
        package = pkgs.phinger-cursors;
        size = 32;
      };
      home-manager.sharedModules = [ { stylix.cursor = config.stylix.cursor; } ];
    })
    # nix-darwin has no console options.
    (lib.optionalAttrs (options ? console) {
      console = {
        font = "ter-v24n";
        packages = [ pkgs.terminus_font ];
        # Load the font in the initrd, so early systemd status lines use it too.
        earlySetup = true;
      };
    })
  ];
}
