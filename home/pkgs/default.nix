{ pkgs, bun2nix }:
with pkgs;
let
  bun2nixPkgs = bun2nix;
  common = [
    #aider-chat
    bun2nixPkgs."atcoder-cli"
    bun2nixPkgs."ccusage"
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
    firefox
    ghostty
    lm-studio
    orbstack
    postman
    raycast
    reaper
    rekordbox
    rustdesk
    unity-hub
  ];

  darwin = [
    karabiner-elements
    mas
    pinentry_mac
  ]
  ++ homebrew;
in
common ++ lib.optionals (!stdenv.isDarwin) nonDarwin ++ lib.optionals stdenv.isDarwin darwin
