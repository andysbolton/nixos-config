{
  description = "Andy's NixOS config.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
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
      url = "github:nix-community/home-manager/release-25.11";
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

    lan-mouse = { url = "github:feschber/lan-mouse/v0.10.0"; };

    # firefox-addons = {
    #   url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # nur.url = "github:nix-community/nur";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = { disko, home-manager, nixpkgs, nix-darwin, nix-homebrew
    , nixpkgs-unstable, self, sops-nix, stylix, ... }@inputs:
    let
      overlays = [
        (final: prev: {
          tokyonight-extras = prev.callPackage ./pkgs/tokyonight-extras.nix { };
        })
      ];

      mkPkgs = system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      mkUnstablePkgs = system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
    in {
      nixosConfigurations.main = let
        system = "x86_64-linux";
        pkgs = mkPkgs system;
        extraSpecialArgs = {
          inherit inputs;
          pkgs-unstable = mkUnstablePkgs system;
        };
      in nixpkgs.lib.nixosSystem {
        inherit system pkgs;
        specialArgs = extraSpecialArgs;
        modules = [
          ./hosts/main/configuration.nix
          ./modules
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          stylix.nixosModules.stylix
          {
            home-manager.users.andy = ./home-manager/linux.nix;
            home-manager.extraSpecialArgs = extraSpecialArgs;
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = false;
          }
          { nixpkgs.overlays = overlays; }
        ];
      };

      darwinConfigurations.work-darwin = let
        system = "aarch64-darwin";
        pkgs = mkPkgs system;
        extraSpecialArgs = {
          inherit inputs;
          pkgs-unstable = mkUnstablePkgs system;
        };
      in nix-darwin.lib.darwinSystem {
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
          }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = false;
              user = "andybolton";
            };
          }
          { nixpkgs.overlays = overlays; }
        ];
      };
    };
}
