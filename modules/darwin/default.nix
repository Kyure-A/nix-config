# https://nix-darwin.github.io/nix-darwin/manual/index.html

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.emacs.darwinModules.twist
  ];

  nixpkgs = {
    hostPlatform = lib.mkDefault "aarch64-darwin";
    overlays = [
      inputs.brew-nix.overlays.default
      inputs.bun2nix.overlays.default
      inputs.nur-packages.overlays.default
      (final: prev: {
        gnome2 = prev.gnome2.overrideScope (
          _gnomeFinal: gnomePrev: {
            gtksourceview = gnomePrev.gtksourceview.overrideAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.gettext ];
            });
          }
        );
      })
      (
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
        }
      )
      (final: _prev: {
        nodePackages = {
          inherit (final) typescript-language-server;
        };
      })
      (import ../../overlays/alcove.nix)
      (import ../../overlays/unity-hub.nix)
      (import ../../overlays/spotify.nix)
      inputs.rust-overlay.overlays.default
      inputs.fenix.overlays.default
      inputs.rustowl-flake.overlays.default
    ];
  };

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs pkgs; };
  };

  homebrew = {
    enable = true;
    masApps = {
      Amphetamine = 937984704;
      DaisyDisk = 411643860;
      Klack = 6446206067;
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  services.tailscale.enable = true;

  security.pam.services.sudo_local.touchIdAuth = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ config.system.primaryUser ];
    };
    gc = {
      automatic = true;
    };
  };

  system = {
    stateVersion = 6;
    defaults = {
      CustomUserPreferences = {
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true; # DS_Store
          DSDontWriteUSBStores = true; # DS_Store
        };

        "com.apple.screencapture" = {
          location = "~/Pictures";
          type = "png";
        };
      };

      NSGlobalDomain = {
        NSDocumentSaveNewDocumentsToCloud = false;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        NSAutomaticCapitalizationEnabled = false;
        "com.apple.swipescrolldirection" = false;
        _HIHideMenuBar = false;
        NSStatusItemSpacing = 8;
        NSStatusItemSelectionPadding = 8;
      };

      dock = {
        autohide = true;
        mineffect = "scale";
        minimize-to-application = true;
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
      };

      menuExtraClock = {
        Show24Hour = true;
        ShowDate = 1;
      };

      trackpad = {
        Clicking = true;
        Dragging = true;
      };
    };
  };

  time.timeZone = "Asia/Tokyo";
}
