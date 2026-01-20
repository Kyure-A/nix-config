{ pkgs, lib, ... }:

let
  masApps = {
    Amphetamine = 937984704;
    DaisyDisk = 411643860;
    GoodNotes = 1444383602;
    Runcat = 1429033973;
    Xcode = 497799835;
  };

  ids = lib.concatStringsSep " " (map toString (builtins.attrValues masApps));

  script = pkgs.writeShellScript "install-mas-apps" ''
    set -euo pipefail

    if ! command -v mas >/dev/null 2>&1; then exit 0; fi
    if ! mas account >/dev/null 2>&1; then exit 0; fi

    installed="$(mas list | awk '{print $1}' || true)"

    for id in ${ids}; do
      if ! printf '%s\n' "$installed" | grep -qx "$id"; then
        echo "[mas] installing $id"
        mas install "$id" || true
      fi
    done
  '';
in
{
  home.packages = [ pkgs.mas ];

  home.activation.installMasApps =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${script}
    '';
}
