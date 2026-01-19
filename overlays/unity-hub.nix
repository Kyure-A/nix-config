final: prev: {
  unity-hub = prev.brewCasks.unity-hub.overrideAttrs (oldAttrs: {
    src = prev.fetchurl {
      url = prev.lib.lists.head oldAttrs.src.urls;
      hash = "sha256-sj1ZdeVk/p5ZQfR75HMDVYnmAPzcyYIAFaRYXQPZK2s=";
    };
  });
}
