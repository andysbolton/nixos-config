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
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-unstable-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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

    import-tree.url = "github:denful/import-tree";

    flake-parts.url = "github:hercules-ci/flake-parts";

    optnix = {
      url = "sourcehut:~watersucks/optnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opnix = {
      url = "github:andysbolton/opnix/fix-hm-network";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wayland-pipewire-idle-inhibit = {
      url = "github:rafaelrc7/wayland-pipewire-idle-inhibit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lan-mouse = {
      url = "github:feschber/lan-mouse";
    };

    fennel-ls-nvim-docs = {
      url = "sourcehut:~micampe/fennel-ls-nvim-docs";
      flake = false;
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # firefox-addons = {
    #   url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # nur.url = "github:nix-community/nur";
  };

  outputs =
    {
      claude-code,
      disko,
      flake-parts,
      home-manager,
      import-tree,
      nix-darwin,
      nix-homebrew,
      nixpkgs,
      opnix,
      stylix,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        flake-parts.flakeModules.modules
        (import-tree ./modules)
      ];

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      flake = {
        nixosConfigurations.main =
          let
            extraSpecialArgs = {
              inherit inputs;
            };
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = extraSpecialArgs;
            modules = [
              ./hosts/main/configuration.nix
              disko.nixosModules.disko
              home-manager.nixosModules.home-manager
              inputs.optnix.nixosModules.optnix
              stylix.nixosModules.stylix
              {
                home-manager.users.andy = ./home-manager/linux.nix;
                home-manager.extraSpecialArgs = extraSpecialArgs;
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = false;
                home-manager.sharedModules = [
                  opnix.homeManagerModules.default
                  stylix.homeModules.stylix
                ];
              }
            ];
          };

        nixosConfigurations.portable =
          let
            extraSpecialArgs = {
              inherit inputs;
            };
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = extraSpecialArgs;
            modules = [
              ./hosts/portable/configuration.nix
              disko.nixosModules.disko
              home-manager.nixosModules.home-manager
              inputs.optnix.nixosModules.optnix
              stylix.nixosModules.stylix
              {
                home-manager.users.andy = ./home-manager/linux.nix;
                home-manager.extraSpecialArgs = extraSpecialArgs;
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = false;
                home-manager.sharedModules = [
                  opnix.homeManagerModules.default
                  stylix.homeModules.stylix
                ];
              }
            ];
          };

        nixosConfigurations.jetkvm-kiosk-aarch64 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [ ./hosts/jetkvm-kiosk.nix ];
        };

        nixosConfigurations.jetkvm-kiosk-x86_64 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./hosts/jetkvm-kiosk.nix ];
        };

        nixosConfigurations.netboot = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/netboot.nix ];
        };

        darwinConfigurations.work-darwin =
          let
            extraSpecialArgs = {
              inherit inputs;
            };
          in
          nix-darwin.lib.darwinSystem {
            specialArgs = extraSpecialArgs;
            modules = [
              ./hosts/work-darwin/configuration.nix
              home-manager.darwinModules.home-manager
              inputs.optnix.darwinModules.optnix
              stylix.darwinModules.stylix
              {
                home-manager.users.andybolton = ./home-manager/darwin.nix;
                home-manager.extraSpecialArgs = extraSpecialArgs;
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = false;
                home-manager.sharedModules = [
                  opnix.homeManagerModules.default
                  stylix.homeModules.stylix
                ];
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
    };
}
