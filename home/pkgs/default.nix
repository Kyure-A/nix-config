{ pkgs }:
with pkgs;
let
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

  nonDarwin = [
    pinentry-all
    docker
  ];

  homebrew = with pkgs.brewCasks; [
    alacritty
    alcom
    crossover
    ghostty
    orbstack
    postman
    raycast
    reaper
    # rekordbox
    rustdesk
    # unity-hub
  ];
  
  darwin = [
    karabiner-elements
    pinentry-mac
  ] ++ homebrew;
in
common ++ lib.optionals (!stdenv.isDarwin) nonDarwin ++ lib.optionals stdenv.isDarwin darwin
