{ pkgs, node2nix }:
{
  home.package = [ node2nix."@google/gemini-cli" ];
}
