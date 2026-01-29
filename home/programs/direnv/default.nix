{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    stdlib = ''
      use_devenv_auto() {
        command -v devenv >/dev/null 2>&1 || return 0

        local dir="$PWD"
        while :; do
          if [ -f "$dir/devenv.nix" ] || [ -f "$dir/devenv.yaml" ]; then
            eval "$(devenv direnvrc)"
            cd "$dir"
            use devenv
            return 0
          fi

          [ "$dir" = "/" ] && return 0
          dir="$(dirname "$dir")"
        done
      }
    '';
  };

  home.file.".envrc".text = ''
    #!/usr/bin/env bash
    # Auto-activate devenv when a devenv config exists in this or a parent directory.
    use_devenv_auto
  '';
}
