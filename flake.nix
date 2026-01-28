{
  description = "Kyure_A's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    nur-packages = {
      url = "github:Kyure-A/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rustowl-flake.url = "github:mrcjkb/rustowl-flake";
    skills-config.url = "path:./skills";
    emacs-d = {
      url = "github:Kyure-A/.emacs.d/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs = {
        brew-api.follows = "brew-api";
        nixpkgs.follows = "nixpkgs";
        nix-darwin.follows = "nix-darwin";
      };
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      bun2nix,
      llm-agents,
      home-manager,
      nixos-wsl,
      rust-overlay,
      fenix,
      nur-packages,
      rustowl-flake,
      nix-darwin,
      skills-config,
      emacs-d,
      brew-nix,
      brew-api, # なぜか入れないと動かない
    }:
    let
      karabiner-elements = (import ./overlays/karabiner-elements.nix);
      lm-studio = (import ./overlays/lm-studio.nix);
      unity-hub = (import ./overlays/unity-hub.nix);
      rekordbox = (import ./overlays/rekordbox.nix);

      overlays = [
        brew-nix.overlays.default
        bun2nix.overlays.default
        llm-agents.overlays.default
        karabiner-elements
        lm-studio
        unity-hub
        rekordbox
        rust-overlay.overlays.default
        fenix.overlays.default
        nur-packages.overlays.default
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
