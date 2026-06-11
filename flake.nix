{
  description = "Andy's NixOS config.";

  nixConfig = {
    extra-substituters = [
      "https://claude-code.cachix.org"
      "https://lan-mouse.cachix.org"
    ];
    extra-trusted-public-keys = [
      "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
      "lan-mouse.cachix.org-1:KlE2AEZUgkzNKM7BIzMQo8w9yJYqUpor1CAUNRY6OyM="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    claude-code.url = "github:sadjow/claude-code-nix";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wayland-pipewire-idle-inhibit = {
      url = "github:rafaelrc7/wayland-pipewire-idle-inhibit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lan-mouse = {
      url = "github:feschber/lan-mouse";
    };

    # firefox-addons = {
    #   url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # nur.url = "github:nix-community/nur";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    {
      claude-code,
      disko,
      home-manager,
      nix-darwin,
      nix-homebrew,
      nixpkgs,
      nixpkgs-unstable,
      opnix,
      self,
      sops-nix,
      stylix,
      ...
    }@inputs:
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
          gatherv2 = prev.callPackage ./pkgs/gatherv2.nix { };
          tokyonight-extras = prev.callPackage ./pkgs/tokyonight-extras.nix { };
        })
        claude-code.overlays.default
      ];

      mkPkgs =
        system:
        import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };

      mkUnstablePkgs =
        system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      nixosConfigurations.main =
        let
          system = "x86_64-linux";
          pkgs = mkPkgs system;
          extraSpecialArgs = {
            inherit inputs;
            pkgs-unstable = mkUnstablePkgs system;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system pkgs;
          specialArgs = extraSpecialArgs;
          modules = [
            ./hosts/main/configuration.nix
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            stylix.nixosModules.stylix
            {
              home-manager.users.andy = ./home-manager/linux.nix;
              home-manager.extraSpecialArgs = extraSpecialArgs;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = false;
              home-manager.sharedModules = [ opnix.homeManagerModules.default ];
            }
          ];
        };

      nixosConfigurations.portable =
        let
          system = "x86_64-linux";
          pkgs = mkPkgs system;
          extraSpecialArgs = {
            inherit inputs;
            pkgs-unstable = mkUnstablePkgs system;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system pkgs;
          specialArgs = extraSpecialArgs;
          modules = [
            ./hosts/portable/configuration.nix
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            stylix.nixosModules.stylix
            {
              home-manager.users.andy = ./home-manager/linux.nix;
              home-manager.extraSpecialArgs = extraSpecialArgs;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = false;
              home-manager.sharedModules = [ opnix.homeManagerModules.default ];
            }
          ];
        };

      darwinConfigurations.work-darwin =
        let
          system = "aarch64-darwin";
          pkgs = mkPkgs system;
          extraSpecialArgs = {
            inherit inputs;
            pkgs-unstable = mkUnstablePkgs system;
          };
        in
        nix-darwin.lib.darwinSystem {
          inherit system pkgs;
          specialArgs = extraSpecialArgs;
          modules = [
            ./hosts/work-darwin/configuration.nix
            home-manager.darwinModules.home-manager
            stylix.darwinModules.stylix
            {
              home-manager.users.andybolton = ./home-manager/darwin.nix;
              home-manager.extraSpecialArgs = extraSpecialArgs;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = false;
              home-manager.sharedModules = [ opnix.homeManagerModules.default ];
            }
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = false;
                user = "andybolton";
              };
            }
          ];
        };
    };
}
