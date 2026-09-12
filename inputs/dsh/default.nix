{
  lib,
  buildNpmPackage,
  fetchurl,
  runCommand,
  makeWrapper,
  nodejs_24,
  bashInteractive,
}:
let
  source = lib.importJSON ./source.json;
  src = runCommand "dsh-source-${source.version}" { } ''
    mkdir -p $out
    tar -xzf ${fetchurl { inherit (source) url hash; }} -C $out --strip-components=1
    # Publish metadata includes unpublished development packages; only the
    # production dependency graph belongs in this application derivation.
    cp ${./package.json} $out/package.json
    cp ${./package-lock.json} $out/package-lock.json
  '';
in
buildNpmPackage {
  pname = "dsh";
  inherit (source) version;
  inherit src;
  nodejs = nodejs_24;
  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-nggwwc7suTjxcfKe3eb6ITKnl59o+gEy6X83BpmyjxY=";
  dontNpmBuild = true;
  nativeBuildInputs = [ makeWrapper ];
  postInstall = ''
    node ${./patch-venice.mjs} \
      $out/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/dsh-llm-pi-ai/lib/index.js \
      ${./venice-compat.mjs}
    substituteInPlace \
      $out/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/dsh-terminal-bash/lib/index.js \
      --replace-fail '"/bin/bash"' '"${lib.getExe bashInteractive}"'
    rm $out/bin/dsh
    makeWrapper ${lib.getExe nodejs_24} $out/bin/dsh \
      --argv0 dsh \
      --add-flags "--expose-internals" \
      --add-flags "$out/lib/node_modules/@deepseek-ai/dsh/lib/bin.js"
  '';
  meta = {
    description = "DeepSeek's agent harness with its official Web interface";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = lib.licenses.mit;
    mainProgram = "dsh";
    platforms = lib.platforms.unix;
  };
}
