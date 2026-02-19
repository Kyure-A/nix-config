{
  fzf,
  zsh-completions,
  zsh-history-substring-search,
  fast-syntax-highlighting,
  nix-zsh-completions,
  zsh-you-should-use,
  agents-md-generator,
  ...
}:
{
  home.file = {
    ".config/sheldon/async".source = ./async;
    ".config/sheldon/sync".source = ./sync;
  };

  programs.sheldon = {
    enable = true;
    settings = {
      shell = "zsh";
      plugins = {
        async = {
          local = "~/.config/sheldon/async";
          use = [ "*.zsh" ];
          apply = [ "defer" ];
        };
        sync = {
          local = "~/.config/sheldon/sync";
          use = [ "*.zsh" ];
          apply = [ "source" ];
        };
        add-zsh-hook = {
          inline = "autoload -U add-zsh-hook";
        };
        colors = {
          inline = "autoload -U colors && zsh-defer colors";
        };
        compinit = {
          inline = "autoload -U compinit && zsh-defer compinit -C";
        };
        fzf = {
          local = "${fzf}";
          use = [
            "shell/completion.zsh"
            "shell/key-bindings.zsh"
          ];
          apply = [ "defer" ];
        };
        predict = {
          inline = "autoload -U predict-on && predict-on";
        };
        zcalc = {
          inline = "autoload -U zcalc";
        };
        zsh-completions = {
          inline = "fpath+=${zsh-completions}/src";
        };
        zsh-history-substring-search = {
          local = "${zsh-history-substring-search}";
          apply = [ "defer" ];
        };
        fast-syntax-highlighting = {
          local = "${fast-syntax-highlighting}";
          apply = [ "defer" ];
        };
        nix-zsh-completions = {
          inline = "fpath+=${nix-zsh-completions}";
        };
        zoxide = {
          inline = ''zsh-defer eval "$(zoxide init zsh --cmd cd)"'';
        };
        zsh-you-should-use = {
          local = "${zsh-you-should-use}";
          apply = [ "defer" ];
        };
        agents-md-generator = {
          local = "${agents-md-generator}";
          use = [ "agents-md-seed.sh" ];
          apply = [ "defer" ];
        };
        zsh-terminfo = {
          inline = "zmodload zsh/terminfo";
        };
      };
      templates = {
        defer = ''
          {{ hooks | get: "pre" | nl }}{% for file in files %}zsh-defer source "{{ file }}"
          {% endfor %}{{ hooks | get: "post" | nl }}'';
      };
    };
  };
}
