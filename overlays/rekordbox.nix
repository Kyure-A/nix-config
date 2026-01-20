final: prev: {
  rekordbox = prev.brewCasks.rekordbox.overrideAttrs (oldAttrs: {
    unpackPhase = ''
      if unzip -t "$src" >/dev/null 2>&1; then
        unzip -q "$src"
        pkg="$(printf '%s\n' *.pkg | head -n1)"
        if [ -z "$pkg" ] || [ "$pkg" = "*.pkg" ]; then
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
}
