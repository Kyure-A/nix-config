{
  description = "Agent Skills";

  inputs = {
    agent-skills.url = "github:Kyure-A/agent-skills-nix";
    anthropic = {
      url = "github:anthropics/skills";
      flake = false;
    };
    vercel = {
      url = "github:vercel-labs/agent-skills";
      flake = false;
    };
    find-skills = {
      url = "github:vercel-labs/skills";
      flake = false;
    };
    ui-skills = {
      url = "github:ibelick/ui-skills";
      flake = false;
    };
    # personal = {
    #   url = "github:Kyure-A/skills-private";
    #   flake = false;
    # };
  };

  outputs =
    {
      self,
      agent-skills,
      anthropic,
      vercel,
      find-skills,
      ...
    }:
    {
      homeManagerModules.default =
        { ... }@args:
        import ./default.nix (
          args
          // {
            inherit
              agent-skills
              anthropic
              find-skills
              vercel
            ;
          }
        );
    };
}
