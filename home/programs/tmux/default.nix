{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    keyMode = "emacs";
    prefix = "C-x";
    baseIndex = 0;
    escapeTime = 0;
    terminal = "screen-256color";
    
    extraConfig = ''
      # Emacs-style window management keybindings
      # C-x 0: kill current pane
      bind-key 0 kill-pane
      
      # C-x 1: kill all panes except current one
      bind-key 1 kill-pane -a
      
      # C-x 2: split window horizontally
      bind-key 2 split-window -v
      
      # C-x 3: split window vertically
      bind-key 3 split-window -h
      
      # C-x o: switch to next pane
      bind-key o select-pane -t :.+
      
      # Additional Emacs-like bindings
      # C-x k: kill current window
      bind-key k kill-window
      
      # C-x b: switch windows (like switch-buffer)
      bind-key b choose-window
      
      # Enable mouse support
      set -g mouse on
      
      # Set status bar
      set -g status-style bg=black,fg=white
      set -g status-left '#[fg=green]#S '
      set -g status-right '#[fg=yellow]%Y-%m-%d %H:%M'
 
      # Set base index for windows and panes
      set-option -g base-index 1
    '';
  };
}
