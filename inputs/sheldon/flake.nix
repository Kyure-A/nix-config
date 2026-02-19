{
  description = "Sheldon Plugins";

  inputs = {
    fzf = {
      url = "github:junegunn/fzf";
      flake = false;
    };
    zsh-completions = {
      url = "github:zsh-users/zsh-completions";
      flake = false;
    };
    zsh-history-substring-search = {
      url = "github:zsh-users/zsh-history-substring-search";
      flake = false;
    };
    fast-syntax-highlighting = {
      url = "github:zdharma-continuum/fast-syntax-highlighting";
      flake = false;
    };
    nix-zsh-completions = {
      url = "github:nix-community/nix-zsh-completions";
      flake = false;
    };
    zsh-you-should-use = {
      url = "github:MichaelAquilina/zsh-you-should-use";
      flake = false;
    };
    agents-md-generator = {
      url = "github:nyosegawa/agents-md-generator";
      flake = false;
    };
  };

  outputs =
    {
      self,
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
      homeManagerModules.default =
        { ... }@args:
        import ./default.nix (
          args
          // {
            inherit
              fzf
              zsh-completions
              zsh-history-substring-search
              fast-syntax-highlighting
              nix-zsh-completions
              zsh-you-should-use
              agents-md-generator
              ;
          }
        );
    };
}
