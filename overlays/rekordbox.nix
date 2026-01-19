final: prev: {
  rekordbox = prev.brewCasks.rekordbox.overrideAttrs (oldAttrs: {
    src = prev.fetchurl {
      url = prev.lib.lists.head oldAttrs.src.urls;
      hash = prev.lib.fakeHash;
    };
  });
}
