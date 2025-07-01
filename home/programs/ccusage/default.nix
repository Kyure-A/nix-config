{ pkgs, node2nix }:
{
  home.packages = [ node2nix."ccusage" ];
}
