{
  description = "Sheldon Plugins";

  inputs = {
    anyframe = {
      url = "github:mollifier/anyframe";
      flake = false;
    };
    fzf = {
      url = "github:junegunn/fzf";
      flake = false;
    };
    zsh-async = {
      url = "github:mafredri/zsh-async";
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
    zsh-syntax-highlighting = {
      url = "github:zsh-users/zsh-syntax-highlighting";
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
      homeManagerModules.default =
        { ... }@args:
        import ./default.nix (
          args
          // {
            inherit
              anyframe
              fzf
              zsh-async
              zsh-completions
              zsh-history-substring-search
              zsh-syntax-highlighting
              agents-md-generator
              ;
          }
        );
    };
}
