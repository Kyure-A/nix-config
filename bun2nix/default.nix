{ pkgs }:
let
  bun2nix = pkgs.bun2nix;
  bunDeps = bun2nix.fetchBunDeps { bunNix = ./bun.nix; };

  platforms = {
    "x86_64-linux" = "linux-amd64";
    "aarch64-linux" = "linux-aarch64";
    "x86_64-darwin" = "darwin-amd64";
    "aarch64-darwin" = "darwin-arm64";
  };
  platform = builtins.getAttr pkgs.system platforms;

  mkBunBin =
    {
      pname,
      version,
      binPath,
    }:
    bun2nix.writeBunApplication {
      inherit pname version bunDeps;
      src = ./.;

      # We only need deps installed; skip bun build/test and avoid fixup.
      buildPhase = ":";
      dontUseBunBuild = true;
      dontUseBunCheck = true;
      dontFixup = true;

      startScript = ''
        ${binPath} "$@"
      '';
    };
in
{
  "@github/copilot-language-server" = mkBunBin {
    pname = "copilot-language-server";
    version = "1.357.0";
    binPath = "./node_modules/@github/copilot-language-server/native/${platform}/copilot-language-server";
  };
  "atcoder-cli" = mkBunBin {
    pname = "acc";
    version = "2.2.0";
    binPath = "./node_modules/.bin/acc";
  };
  "ccusage" = mkBunBin {
    pname = "ccusage";
    version = "15.9.7";
    binPath = "./node_modules/.bin/ccusage";
  };
}
