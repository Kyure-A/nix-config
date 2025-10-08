{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };

    brews = [
      "docker-compose"
      "pinentry-mac"
      "tectonic"
    ];

    casks = [
      "alacritty"
      "alcom"
      "chatgpt"
      "claude"
      "crossover"
      "dbvisualizer"
      "firefox"
      "lm-studio"
      "orbstack"
      "postman"
      "raycast"
      "reaper"
      "rekordbox"
      "unity-hub"
      "visual-studio-code"
    ];

    masApps = {
      DaisyDisk = 411643860;
      GoodNotes = 1444383602;
      Runcat = 1429033973;
      Structured = 1499198946;
      SwiftPlaygrounds = 1496833156;
      Xcode = 497799835;
    };
  };
}
