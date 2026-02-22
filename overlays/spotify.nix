final: prev: {
  brewCasks = prev.brewCasks // {
    spotify = prev.brewCasks.spotify.overrideAttrs (oldAttrs: {
      src = prev.fetchurl {
        url = if oldAttrs.src ? urls then prev.lib.lists.head oldAttrs.src.urls else oldAttrs.src.url;
        hash = "sha256-57g0sPOg3yGXKfwg0Qcz5wxym53pVwl5PGQST1PQ72w=";
      };
    });
  };
}
