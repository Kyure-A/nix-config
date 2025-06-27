{ pkgs, node2nix }:
{
  home.packages = [ node2nix."@google/gemini-cli" ];
}
