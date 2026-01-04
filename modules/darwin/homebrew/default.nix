{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };

    brews = [
      "pinentry-mac"
    ];

    casks = [
      "alacritty"
      "alcom"
      "crossover"
      "firefox"
      "lm-studio"
      "orbstack"
      "postman"
      "raycast"
      "reaper"
      "rekordbox"
      "rustdesk"
      "unity-hub"
    ];

    masApps = {
      Amphetamine = 937984704;
      DaisyDisk = 411643860;
      GoodNotes = 1444383602;
      Runcat = 1429033973;
      Structured = 1499198946;
      Xcode = 497799835;
    };
  };
}
