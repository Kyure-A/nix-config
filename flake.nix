{
  description = "Kyure_A's NixOS Config";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

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
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
    };
    emacs = {
      url = "github:Kyure-A/.emacs.d";
      inputs.blueprint.follows = "blueprint";
      inputs.emacs.follows = "emacs-overlay";
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
    llm-agents.url = "github:numtide/llm-agents.nix";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur-packages = {
      url = "github:Kyure-A/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rustowl-flake.url = "github:mrcjkb/rustowl-flake";
    sheldon.url = "path:./inputs/sheldon";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      legacy-gtk = final: prev: {
        gnome2 = prev.gnome2.overrideScope (
          _gnomeFinal: gnomePrev: {
            gtksourceview = gnomePrev.gtksourceview.overrideAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.gettext ];
            });
          }
        );
      };
      emacs-git-patches =
        final: prev:
        prev.lib.optionalAttrs (prev ? emacs-git) {
          emacs-git = prev.emacs-git.overrideAttrs (old: {
            patches = final.lib.filter (
              patch:
              let
                patchName = builtins.baseNameOf (toString patch);
                stalePatches = [
                  "fix-off-by-one-mistake-80851-CVE-2026-6861.patch"
                  "01_all_treesit-0.26.patch"
                  "02_all_ts-query-pred.patch"
                ];
              in
              !(final.lib.any (name: final.lib.hasInfix name patchName) stalePatches)
            ) old.patches;
          });
        };
      node-packages = final: _prev: {
        nodePackages = {
          inherit (final) typescript-language-server;
        };
      };
      alcove = (import ./overlays/alcove.nix);
      spotify = (import ./overlays/spotify.nix);
      unity-hub = (import ./overlays/unity-hub.nix);

      overlays = [
        inputs.brew-nix.overlays.default
        inputs.bun2nix.overlays.default
        inputs.nur-packages.overlays.default
        legacy-gtk
        emacs-git-patches
        node-packages
        alcove
        spotify
        unity-hub
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
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = overlays;
      };

      mkDarwinRebuildApp =
        system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          darwin-rebuild = pkgs.writeShellApplication {
            name = "darwin-rebuild";
            runtimeInputs = [ inputs.nix-darwin.packages.${system}.darwin-rebuild ];
            text = ''
              exec darwin-rebuild switch --flake .#darwin --impure "$@"
            '';
          };
        in
        {
          type = "app";
          program = "${darwin-rebuild}/bin/darwin-rebuild";
        };
    in
    flake
    // {
      apps.aarch64-darwin = (flake.apps.aarch64-darwin or { }) // rec {
        darwin-rebuild = mkDarwinRebuildApp "aarch64-darwin";
        default = darwin-rebuild;
      };

      formatter =
        let
          mkFormatter =
            system:
            (inputs.treefmt-nix.lib.evalModule inputs.nixpkgs.legacyPackages.${system} {
              programs.nixfmt.enable = true;
            }).config.build.wrapper;
        in
        {
          x86_64-linux = mkFormatter "x86_64-linux";
          aarch64-darwin = mkFormatter "aarch64-darwin";
        };
    };
}
