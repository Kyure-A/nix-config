final: prev: {
  unity-hub = prev.brewCasks.unity-hub.overrideAttrs (oldAttrs: {
    src = prev.fetchurl {
      url = prev.lib.lists.head oldAttrs.src.urls;
      hash = "sha256-9rR97hWa3UyxXvuH2AoM70ttGt9udRd3CDy5Uj7DNgI=";
    };
  });
}
