{ pkgs }:
let
  bun2nix = pkgs.bun2nix;
  bunDeps = bun2nix.fetchBunDeps { bunNix = ./bun.nix; };

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
  "atcoder-cli" = mkBunBin {
    pname = "acc";
    version = "2.2.0";
    binPath = "./node_modules/.bin/acc";
  };
}
