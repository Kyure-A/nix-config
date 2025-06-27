{ pkgs, node2nix }:
{
  home.packages = [ node2nix."@mariozechner/claude-bridge" ];
}
