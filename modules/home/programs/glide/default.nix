{
  home.file.".config/glide/glide.toml".text = ''
    [settings]
    default_keys = true
    default_layout_kind = "scroll"

    [keys]
    "Alt + H" = "disable"
    "Alt + J" = "disable"
    "Alt + K" = "disable"
    "Alt + L" = "disable"
    "Alt + Shift + H" = "disable"
    "Alt + Shift + J" = "disable"
    "Alt + Shift + K" = "disable"
    "Alt + Shift + L" = "disable"
    "Alt + Ctrl + H" = "disable"
    "Alt + Ctrl + J" = "disable"
    "Alt + Ctrl + K" = "disable"
    "Alt + Ctrl + L" = "disable"

    "Alt + B" = { move_focus = "left" }
    "Alt + N" = { move_focus = "down" }
    "Alt + P" = { move_focus = "up" }
    "Alt + F" = { move_focus = "right" }
    "Alt + V" = "next_layout"
    "Alt + Shift + V" = "prev_layout"

    "Alt + Shift + B" = { move_node = "left" }
    "Alt + Shift + N" = { move_node = "down" }
    "Alt + Shift + P" = { move_node = "up" }
    "Alt + Shift + F" = { move_node = "right" }

    "Alt + Ctrl + B" = { resize = { direction = "left", percent = 5 } }
    "Alt + Ctrl + N" = { resize = { direction = "down", percent = 5 } }
    "Alt + Ctrl + P" = { resize = { direction = "up", percent = 5 } }
    "Alt + Ctrl + F" = { resize = { direction = "right", percent = 5 } }

    [settings.experimental.scroll]
    enable = true
    visible_columns = 2
    center_focused_column = "on_overflow"
    column_width_presets = [0.5, 0.667, 1.0]
    new_window_in_column = "new_column"
  '';
}
