{ stdenv, lib }:
stdenv.mkDerivation {
  pname = "dsh-app";
  version = "0.2.1";
  src = ./.;
  buildPhase = ''
    runHook preBuild
    $CC -O2 -fobjc-arc -fmodules -Wall -Wextra -mmacosx-version-min=13.0 \
      -framework Cocoa -framework WebKit -framework ImageIO main.m -o DSH
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    app="$out/Applications/DSH.app/Contents"
    mkdir -p "$app/MacOS" "$app/Resources"
    cp DSH "$app/MacOS/DSH"
    ./DSH --write-icon "$app/Resources/DSH.icns"
    cp Info.plist "$app/Info.plist"
    runHook postInstall
  '';
  meta = {
    description = "Native macOS window for the shared local DSH harness";
    platforms = lib.platforms.darwin;
    license = lib.licenses.mit;
  };
}
