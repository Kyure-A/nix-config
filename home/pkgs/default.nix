{ pkgs }:
with pkgs;
let
  targets.darwin.copyApps.enable = true;
  
  common = [
    #aider-chat
    bun
    claude-code
    codex
    delta
    deno
    docker-compose
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
    #ollama
    # omnisharp-roslyn # C#
    online-judge-tools
    openssl
    rana # nostr key miner
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
