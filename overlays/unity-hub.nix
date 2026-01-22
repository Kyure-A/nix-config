final: prev: {
  brewCasks = prev.brewCasks // {
    unity-hub = prev.brewCasks.unity-hub.overrideAttrs (oldAttrs: {
      src = prev.fetchurl {
        url = if oldAttrs.src ? urls then prev.lib.lists.head oldAttrs.src.urls else oldAttrs.src.url;
        hash = "sha256-9rR97hWa3UyxXvuH2AoM70ttGt9udRd3CDy5Uj7DNgI=";
      };
    });
  };
}
