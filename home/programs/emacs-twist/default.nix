{ emacs-config }:
{
  programs.emacs-twist = {
    enable = true;
    emacsclient.enable = true;
    createInitFile = true;
    createManifestFile = true;
    config = emacs-config;
  };
}
