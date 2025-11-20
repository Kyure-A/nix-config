{ pkgs }:
with pkgs;
let
  targets.darwin.copyApps.enable = true;
  
  common = [
    aider-chat
    baobab
    bun
    claude-code
    codex
    delta
    deno
    # dotnet-sdk # C#
    emacs-lsp-booster
    eza
    gcc
    ghq
    glance
    gnumake
    gnupg
    keybase
    fastfetch
    nixd
    nixpkgs-fmt
    nodejs_22
    nodePackages.typescript-language-server
    ollama
    # omnisharp-roslyn # C#
    online-judge-tools
    openssl
    ripgrep
    rust-bin.stable.latest.default
    rust-analyzer
    satysfi
    tectonic
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
        karabiner-elements
      ]
    else
      [ ];
in
common ++ nonDarwin ++ darwin
