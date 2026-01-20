final: prev: {
  brewCasks =
    prev.brewCasks
    // {
      rekordbox = prev.brewCasks.rekordbox.overrideAttrs (oldAttrs: {
        unpackPhase = ''
          if unzip -t "$src" >/dev/null 2>&1; then
            unzip -q "$src"
            pkg="$(fd -t f -e pkg -d 3 . | head -n1)"
            if [ -z "$pkg" ]; then
              echo "No .pkg found after unzip"
              exit 1
            fi
            xar -xf "$pkg"
          else
            xar -xf "$src"
          fi
          for pkg in $(cat Distribution | grep -oE "#.+\.pkg" | sed -e "s/^#//" -e "s/$/\/Payload/"); do
            zcat $pkg | cpio -i
          done
        '';
      });
    };
}
