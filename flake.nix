{
  description = "Andy's NixOS config.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-25.05";
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
  };

  outputs = { self, nixpkgs, home-manager, stylix, disko, sops-nix
    , nixpkgs-unstable, ... }@inputs: {
      nixosConfigurations.main = let
        extraSpecialArgs = {
          inherit inputs;
          nixpkgs-unstable = import nixpkgs-unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
      in nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = extraSpecialArgs;
        modules = [
          ./hosts/main/configuration.nix
          ./modules
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            home-manager.users.andy = ./home-manager/home.nix;
            home-manager.extraSpecialArgs = extraSpecialArgs;
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = false;
          }
          stylix.nixosModules.stylix
        ];
      };
    };
}
