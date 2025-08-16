{ pkgs }:
with pkgs;
let
  common = [
    aider-chat
    baobab
    bun
    claude-code
    delta
    deno
    dotnet-sdk # C#
    emacs-lsp-booster
    eza
    gcc
    ghq
    glance
    gnumake
    gnupg
    keybase
    neofetch
    nixd
    nixpkgs-fmt
    nodejs_22
    nodePackages.typescript-language-server
    ollama
    omnisharp-roslyn # C#
    online-judge-tools
    openssl
    ripgrep
    rust-bin.stable.latest.default
    rust-analyzer
    satysfi
    sheldon
    # tectonic
    tmux
    tree-sitter
    vscode
    web-ext # mozilla
    zsh-defer
  ];

  nonDarwin =
    if !stdenv.isDarwin then
      [
        pinentry-all
        docker
      ]
    else
      [ ];
  darwin =
    if stdenv.isDarwin then
      [
        warp-terminal
        karabiner-elements
      ]
    else
      [ ];
in
common ++ nonDarwin ++ darwin
