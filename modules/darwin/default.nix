# https://nix-darwin.github.io/nix-darwin/manual/index.html

{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  nixpkgs = {
    hostPlatform = lib.mkDefault "aarch64-darwin";
    overlays = [
      inputs.brew-nix.overlays.default
      inputs.bun2nix.overlays.default
      inputs.llm-agents.overlays.default
      (import ../../overlays/karabiner-elements.nix)
      (import ../../overlays/lm-studio.nix)
      (import ../../overlays/unity-hub.nix)
      (import ../../overlays/rekordbox.nix)
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

  system.primaryUser = "kyre";

  homebrew = {
    enable = true;
    masApps = {
      Amphetamine = 937984704;
      DaisyDisk = 411643860;
      GoodNotes = 1444383602;
      Klack = 6446206067;
      Runcat = 1429033973;
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "kyre"
      ];
    };
    gc = {
      automatic = true;
    };
  };

  services = {
    karabiner-elements = {
      enable = true;
      package = pkgs.karabiner-elements.overrideAttrs (old: {
        version = "14.13.0";

        src = pkgs.fetchurl {
          inherit (old.src) url;
          hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
        };

        dontFixup = true;
      });
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
        NSStatusItemSpacing = 8;
        NSStatusItemSelectionPadding = 8;
      };

      dock = {
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
