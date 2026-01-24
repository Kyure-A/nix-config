{
  config,
  lib,
  pkgs,
  isWsl ? false,
  ...
}:
{
  config = lib.mkMerge [
    {
      nix = {
        settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        optimise = {
          automatic = true;
          dates = [ "00:00" ];
        };
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };
      };

      networking = {
        hostName = "nixos";
        networkmanager.enable = true;
      };

      time.timeZone = "Asia/Tokyo";

      i18n = {
        defaultLocale = "en_US.UTF-8";
        extraLocaleSettings = {
          LC_ADDRESS = "en_US.UTF-8";
          LC_IDENTIFICATION = "en_US.UTF-8";
          LC_MEASUREMENT = "en_US.UTF-8";
          LC_MONETARY = "en_US.UTF-8";
          LC_NAME = "en_US.UTF-8";
          LC_NUMERIC = "en_US.UTF-8";
          LC_PAPER = "en_US.UTF-8";
          LC_TELEPHONE = "en_US.UTF-8";
          LC_TIME = "en_US.UTF-8";
        };
        inputMethod = {
          enable = true;
          type = "fcitx5";
          fcitx5.addons = with pkgs; [
            fcitx5-mozc
            fcitx5-anthy
          ];
        };
      };

      fonts = {
        packages = with pkgs; [
          noto-fonts-cjk-serif
          noto-fonts-cjk-sans
          noto-fonts-color-emoji
          nerd-fonts.fira-code
        ];
        fontDir.enable = true;
        fontconfig = {
          allowBitmaps = false;
          allowType1 = false;
          defaultFonts = {
            serif = [
              "Noto Serif CJK JP"
              "Noto Color Emoji"
            ];
            sansSerif = [
              "Noto Sans CJK JP"
              "Noto Color Emoji"
            ];
            monospace = [
              "FiraCode Nerd Font"
              "Noto Color Emoji"
            ];
            emoji = [ "Noto Color Emoji" ];
          };
        };
      };

      security.rtkit.enable = true;

      services = {
        xserver = {
          enable = true;
          displayManager = {
            gdm.enable = true;
          };
          xkb = {
            variant = "";
            layout = "us";
          };
        };
        pcscd.enable = true;
        printing.enable = true;
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };
        pulseaudio.enable = false;
      };

      users.users.kyre = {
        isNormalUser = true;
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        shell = pkgs.zsh;
        useDefaultShell = true;
        packages = with pkgs; [ ];
      };

      programs = {
        zsh.enable = true;
        gnupg = {
          agent = {
            enable = true;
            pinentryPackage = pkgs.pinentry-all;
            enableSSHSupport = true;
          };
        };
      };

      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "25.05";
    }
    (lib.mkIf (!isWsl) {
      boot = {
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;
      };
      services.xserver.desktopManager.gnome.enable = true;
    })
    (lib.mkIf isWsl {
      wsl = {
        enable = true;
        defaultUser = "kyre";
      };
    })
  ];
}
