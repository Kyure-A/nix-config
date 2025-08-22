{
  pkgs,
  emacs-config,
  node2nix,
}:
let
  alacritty = import ./alacritty;
  ccusage = import ./ccusage { inherit pkgs node2nix; };
  claude-bridge = import ./claude-bridge { inherit pkgs node2nix; };
  copilot-language-server = import ./copilot-language-server { inherit pkgs node2nix; };
  emacs-twist = import ./emacs-twist { inherit emacs-config; };
  gemini-cli = import ./gemini-cli { inherit pkgs node2nix; };
  git = import ./git { inherit pkgs; };
  karabiner = import ./karabiner;
  sheldon = import ./sheldon;
  starship = import ./starship;
  tmux = import ./tmux { inherit pkgs; };
  zsh = import ./zsh { inherit pkgs; };
  common = [
    ccusage
    claude-bridge
    copilot-language-server
    emacs-twist
    gemini-cli
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
