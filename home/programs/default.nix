{
  pkgs,
  bun2nix,
  inputs,
}:
let
  alacritty = import ./alacritty;
  copilot-language-server = import ./copilot-language-server { inherit pkgs bun2nix; };
  emacs-twist = import ./emacs-twist;
  git = import ./git { inherit pkgs; };
  karabiner = import ./karabiner;
  sheldon = import ./sheldon;
  starship = import ./starship;
  tmux = import ./tmux { inherit pkgs; };
  zsh = import ./zsh { inherit pkgs; };
  common = [
    copilot-language-server
    emacs-twist
    git
    sheldon
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
