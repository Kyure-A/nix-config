{
  description = "Kyure_A's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    rustowl-flake.url = "github:mrcjkb/rustowl-flake";
    skills-config.url = "path:./inputs/skills";
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
    inputs:
    let
      karabiner-elements = (import ./overlays/karabiner-elements.nix);
      lm-studio = (import ./overlays/lm-studio.nix);
      unity-hub = (import ./overlays/unity-hub.nix);
      rekordbox = (import ./overlays/rekordbox.nix);

      overlays = [
        inputs.brew-nix.overlays.default
        inputs.bun2nix.overlays.default
        inputs.llm-agents.overlays.default
        karabiner-elements
        lm-studio
        unity-hub
        rekordbox
        inputs.rust-overlay.overlays.default
        inputs.fenix.overlays.default
        inputs.rustowl-flake.overlays.default
      ];

      flake = inputs.blueprint {
        inherit inputs;
        systems = [
          "x86_64-linux"
          "aarch64-darwin"
        ];
        nixpkgs.overlays = overlays;
      };
    in
    flake
    // {
      formatter = {
        x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
        aarch64-darwin = inputs.nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;
      };
    };
}
