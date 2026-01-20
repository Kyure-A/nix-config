{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # cleanup = "uninstall";
    };

    casks = [
      "firefox"
      "lm-studio"
      "unity-hub"
    ];
  };
}
