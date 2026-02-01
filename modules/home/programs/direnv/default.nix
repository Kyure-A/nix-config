{ config, ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  home.file.".envrc".text = ''
    #!/usr/bin/env bash
    if [ -f "flake.nix" ]; then
      use flake
    else
      eval "$(devenv direnvrc)"
      use devenv
    fi
  '';

  home.file.".config/direnv/direnv.toml".text = ''
    [whitelist]
    exact = [ "${config.home.homeDirectory}/.envrc" ]
  '';
}
