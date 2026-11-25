{ inputs, ... }:
let
  overlays = [
    (final: prev: {
      _1password-gui =
        if prev.stdenv.hostPlatform.isDarwin then
          prev._1password-gui.overrideAttrs (old: {
            src = old.src.overrideAttrs {
              outputHash = "sha256-WrWbGzBK65tVNl9Dc3OnJURiPpfbNLOYUJcVT0ETaAs=";
            };
          })
        else
          prev._1password-gui;

      gatherv2 = prev.callPackage ../pkgs/gatherv2.nix { };

      tokyonight-extras = prev.callPackage ../pkgs/tokyonight-extras.nix { };

      unstable =
        import
          (
            if prev.stdenv.hostPlatform.isDarwin then
              inputs.nixpkgs-unstable-darwin
            else
              inputs.nixpkgs-unstable
          )
          {
            system = prev.stdenv.hostPlatform.system;
            overlays = unstableOverlays;
            config.allowUnfree = true;
          };
    })
    inputs.claude-code.overlays.default
  ];

  unstableOverlays = [
    (final: prev: {
      yabai = prev.yabai.overrideAttrs (old: {
        version = "7.1.26";
        src = prev.fetchFromGitHub {
          owner = "VenusCrazy";
          repo = "yabai";
          rev = "21a461726cfa84052cae48165f1a46c3b70839fa";
          hash = "sha256-mr84vr7yXrZe4UBUayaXwmdlozREpmsDWeOmLEz2dPQ=";
        };
        patches = (old.patches or [ ]) ++ [ ../pkgs/yabai-osax-seal-order.patch ];

        # macOS 27 dyld refuses to dlopen a Mach-O without LC_UUID, which
        # nixpkgs strips for reproducibility; the scripting addition is
        # dlopen'd into Dock, so it must keep its UUID.
        postPatch = (old.postPatch or "") + ''
          substituteInPlace makefile --replace-fail " -Wl,-no_uuid" ""
        '';
      });
    })
  ];
  nixpkgs = {
    nixpkgs.overlays = overlays;
    nixpkgs.config.allowUnfree = true;
  };
in
{
  flake.modules = {
    nixos.nixpkgs = nixpkgs;
    darwin.nixpkgs = nixpkgs;
  };
}
