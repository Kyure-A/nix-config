{
  description = "Kyure_A's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rustowl-flake.url = "github:mrcjkb/rustowl-flake";
    skills-config.url = "path:./skills";
    emacs-d = {
      url = "github:Kyure-A/.emacs.d";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-wsl,
      rust-overlay,
      fenix,
      rustowl-flake,
      nix-darwin,
      skills-config,
      emacs-d,
    }:
    let
      karabiner-elements = (import ./overlays/karabiner-elements.nix);

      overlays = [
        karabiner-elements
        rust-overlay.overlays.default
        fenix.overlays.default
        rustowl-flake.overlays.default
      ];
    in
    {
      formatter = {
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;
      };

      darwinConfigurations = (
        import ./hosts/darwin {
          inherit
            self
            nixpkgs
            home-manager
            nix-darwin
            overlays
            emacs-d
            skills-config
            ;
        }
      );

      nixosConfigurations =
        (import ./hosts/wsl {
          inherit
            self
            nixpkgs
            home-manager
            nixos-wsl
            overlays
            emacs-d
            skills-config
            ;
        })
        // (import ./hosts/x230 {
          inherit
            self
            nixpkgs
            home-manager
            overlays
            emacs-d
            skills-config
            ;
        });
    };
}
