{ pkgs }:
let
  alacritty = import ./alacritty;
  copilot-language-server = import ./copilot-language-server { inherit pkgs; };
  direnv = import ./direnv;
  emacs-twist = import ./emacs-twist;
  git = import ./git { inherit pkgs; };
  karabiner = import ./karabiner;
  starship = import ./starship;
  tmux = import ./tmux { inherit pkgs; };
  zsh = import ./zsh { inherit pkgs; };
  common = [
    copilot-language-server
    direnv
    emacs-twist
    git
    starship
    tmux
    zsh
  ];
  darwin =
    if pkgs.stdenv.isDarwin then
      [
        alacritty
        karabiner
      ]
    else
      [ ];
in
common ++ darwin
