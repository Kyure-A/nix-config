{
  pkgs,
  bun2nix,
  llmAgents,
}:
with pkgs;
let
  bun2nixPkgs = bun2nix;
  common = [
    #aider-chat
    bun2nixPkgs."atcoder-cli"
    bun
    llmAgents.claude-code
    llmAgents.codex
    cosense-cli
    delta
    deno
    devenv
    docker-compose
    eza
    ffmpeg
    fzf
    gcc
    llmAgents.gemini-cli
    gh
    ghq
    glance
    gnumake
    gnupg
    keybase
    kimi-code
    llmAgents.ccusage
    manaba-cli
    fastfetch
    nixpkgs-fmt
    nodejs_22
    ollama
    online-judge-tools
    llmAgents.opencode
    openssl
    llmAgents.qwen-code
    ripgrep
    rust-bin.stable.latest.default
    #satysfi
    tectonic
    tmux
    web-ext # mozilla
    zoxide
    zsh-defer
  ];

  nonDarwin = [
    pinentry-all
    docker
  ];

  homebrew = with pkgs.brewCasks; [
    alacritty
    alcom
    alcove
    antigravity
    codex-app
    pkgs."codex-switcher"
    #crossover
    firefox
    ghostty
    orbstack
    raycast
    #rustdesk
    spotify
    unity-hub
  ];

  darwin = [
    mas
    pinentry_mac
  ]
  ++ homebrew;
in
common ++ lib.optionals (!stdenv.isDarwin) nonDarwin ++ lib.optionals stdenv.isDarwin darwin
