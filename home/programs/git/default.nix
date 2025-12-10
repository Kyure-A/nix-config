{ pkgs }:
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Kyure_A";
        email = "49436968+Kyure-A@users.noreply.github.com";
      };

      core = {
        editor = "emacs -nw";
        quotepath = false;
        pager = "delta";
      };

      github = {
        user = "Kyure-A";
      };

      init = {
        defaultBranch = "master";
      };

      merge = {
        conflictstyle = "diff3";
      };

      diff = {
        colorMoved = "default";
      };

      interactive = {
        diffFilter = "${pkgs.delta} --color-only";
      };

      delta = {
        side-by-side = true;
        navigate = true;
        light = false;
      };
    };
  };
}
