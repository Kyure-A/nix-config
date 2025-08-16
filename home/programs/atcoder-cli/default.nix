{ pkgs, node2nix }:
{
  home.packages = [ node2nix."atcoder-cli" ];
}
