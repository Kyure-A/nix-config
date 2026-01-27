{ pkgs, node2nix }:
let
  platforms = {
    "x86_64-linux" = "linux-amd64";
    "aarch64-linux" = "linux-aarch64";
    "x86_64-darwin" = "darwin-amd64";
    "aarch64-darwin" = "darwin-arm64";
  };
  platform = builtins.getAttr pkgs.system platforms;
in
{
  home.packages = [ node2nix."@github/copilot-language-server" ];

  home.sessionVariables = {
    COPILOT_LANGUAGE_SERVER_PATH = "${
      node2nix."@github/copilot-language-server"
    }/lib/node_modules/@github/copilot-language-server/native/${platform}/copilot-language-server";
  };
}
