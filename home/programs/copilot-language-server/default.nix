{ pkgs, bun2nix }:
let
  platforms = {
    "x86_64-linux" = "linux-amd64";
    "aarch64-linux" = "linux-aarch64";
    "x86_64-darwin" = "darwin-amd64";
    "aarch64-darwin" = "darwin-arm64";
  };
  platform = builtins.getAttr pkgs.system platforms;
  copilot = bun2nix."@github/copilot-language-server";
in
{
  home.packages = [ copilot ];

  home.sessionVariables = {
    COPILOT_LANGUAGE_SERVER_PATH = "${copilot}/share/copilot-language-server/node_modules/@github/copilot-language-server/native/${platform}/copilot-language-server";
  };
}
