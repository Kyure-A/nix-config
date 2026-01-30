{ config, ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  home.file.".envrc".text = ''
    #!/usr/bin/env bash
    eval "$(devenv direnvrc)"
    use devenv
  '';

  home.file.".config/direnv/direnv.toml".text = ''
    [whitelist]
    exact = [ "${config.home.homeDirectory}/.envrc" ]
  '';
}
