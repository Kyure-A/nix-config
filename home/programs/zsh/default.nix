{ pkgs }:
let
  load-zsh-defer = ''source "${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh"'';
  load-sheldon = ''
    eval "$(sheldon source)"
    if [[ $TERM != "dumb" ]]; then
       eval "$(sheldon completions --shell=zsh)"
    fi
  '';
  text = builtins.concatStringsSep "\n" [
    load-zsh-defer
    load-sheldon
  ];
in
{
  # home.file = {
  #   ".zshrc".source = pkgs.writeText ".zshrc" text;
  # };
  programs.zsh = {
    enable = true;
  };
}
