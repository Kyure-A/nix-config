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
    eza
    gcc
    gemini-cli
    ghq
    glance
    gnumake
    gnupg
    keybase
    fastfetch
    nixpkgs-fmt
    nodejs_22
    #ollama
    online-judge-tools
    opencode
    openssl
    ripgrep
    rust-bin.stable.latest.default
    satysfi
    tectonic
    tmux
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
