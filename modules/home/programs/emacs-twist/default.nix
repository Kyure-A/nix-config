{ ... }:
{
  programs.emacs-twist = {
    enable = true;
    emacsclient.enable = true;
    createInitFile = true;
    createManifestFile = true;
  };
}
