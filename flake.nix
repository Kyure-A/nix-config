{
  description = "Kyure_A's NixOS Config";

  inputs = {
    agent-skills.url = "path:./inputs/skills";
    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs = {
        brew-api.follows = "brew-api";
        nix-darwin.follows = "nix-darwin";
        nixpkgs.follows = "nixpkgs";
      };
    };
    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs = {
      url = "github:Kyure-A/.emacs.d/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rustowl-flake.url = "github:mrcjkb/rustowl-flake";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      karabiner-elements = (import ./overlays/karabiner-elements.nix);
      lm-studio = (import ./overlays/lm-studio.nix);
      rekordbox = (import ./overlays/rekordbox.nix);
      unity-hub = (import ./overlays/unity-hub.nix);

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
      formatter =
        let
          mkFormatter =
            system:
            (inputs.treefmt-nix.lib.evalModule inputs.nixpkgs.legacyPackages.${system} {
              modules = [
                {
                  programs.nixfmt.enable = true;
                }
              ];
            }).config.build.wrapper;
        in
        {
          x86_64-linux = mkFormatter "x86_64-linux";
          aarch64-darwin = mkFormatter "aarch64-darwin";
        };
    };
}
