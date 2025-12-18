{ emacs-config, earlyInitEl }:
{
  programs.emacs-twist = {
    enable = true;
    emacsclient.enable = true;
    createInitFile = true;
    createManifestFile = true;
    config = emacs-config;
    earlyInitFile = earlyInitEl;
  };
}
