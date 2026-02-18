{
  anyframe,
  fzf,
  zsh-async,
  zsh-completions,
  zsh-history-substring-search,
  zsh-syntax-highlighting,
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
        anyframe = {
          local = "${anyframe}";
        };
        colors = {
          inline = "autoload -U colors && zsh-defer colors";
        };
        compinit = {
          inline = "autoload -U compinit && zsh-defer compinit -C";
        };
        fzf = {
          local = "${fzf}";
        };
        predict = {
          inline = "autoload -U predict-on && predict-on";
        };
        starship = {
          inline = ''
            eval "$(starship init zsh)"
          '';
        };
        zcalc = {
          inline = "autoload -U zcalc";
        };
        zsh-async = {
          local = "${zsh-async}";
        };
        zsh-complations = {
          local = "${zsh-completions}";
          apply = [ "defer" ];
        };
        zsh-history-substring-search = {
          local = "${zsh-history-substring-search}";
          apply = [ "defer" ];
        };
        zsh-syntax-highlighting = {
          local = "${zsh-syntax-highlighting}";
          apply = [ "defer" ];
        };
        agents-md-generator = {
          local = "${agents-md-generator}";
          use = [ "agents-md-seed.sh" ];
          apply = [ "defer" ];
        };
        agents-md-generator = {
          github = "nyosegawa/agents-md-generator";
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
