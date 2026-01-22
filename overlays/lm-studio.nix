final: prev: {
  brewCasks = prev.brewCasks // {
    lm-studio = prev.brewCasks.lm-studio.overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ prev.findutils ];
      unpackPhase = ''
        7zz x -snld "$src" || true
        if [ ! -d "LM Studio.app" ]; then
          echo "LM Studio.app not found after unpack"
          exit 1
        fi

        python_dir="$(find "LM Studio.app" -path "*app-mlx-generate-mac14-arm64@*/bin" -type d | head -n1 || true)"
        if [ -n "$python_dir" ]; then
          if [ ! -e "$python_dir/python3.11" ] && [ -e "$python_dir/python" ]; then
            ln -s python "$python_dir/python3.11"
          fi
        fi
      '';
    });
  };
}
