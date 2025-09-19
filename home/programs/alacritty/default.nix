{
  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        TERM = "xterm-256color";
      };

      window = {
        padding = {
          x = 16;
          y = 16;
        };
        opacity = 0.95;
        decorations = "transparent";
      };

      font = {
        normal = {
          family = "FiraCode Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "FiraCode Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "FiraCode Nerd Font";
          style = "Italic";
        };
        size = 13.0;
      };

      colors = {
        primary = {
          background = "#272822";
          foreground = "#F8F8F2";
        };

        normal = {
          black = "#272822";
          red = "#F92672";
          green = "#A6E22E";
          yellow = "#F4BF75";
          blue = "#66D9EF";
          magenta = "#AE81FF";
          cyan = "#A1EFE4";
          white = "#F8F8F2";
        };

        bright = {
          black = "#75715E";
          red = "#F92672";
          green = "#A6E22E";
          yellow = "#F4BF75";
          blue = "#66D9EF";
          magenta = "#AE81FF";
          cyan = "#A1EFE4";
          white = "#F9F8F5";
        };
      };

      cursor = {
        style = {
          shape = "Block";
          blinking = "Off";
        };
      };

      terminal = {
        shell = {
          program = "zsh";
          args = [
            "-l"
            "-c"
            "tmux a -t 0 || tmux"
          ];
        };
      };
    };
  };
}
