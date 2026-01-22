{
  description = "Agent Skills";

  inputs = {
    agent-skills.url = "github:Kyure-A/agent-skills-nix";
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };
    vercel-skills = {
      url = "github:vercel-labs/agent-skills";
      flake = false;
    };
    my-skills = {
      url = "github:Kyure-A/skills";
      flake = false;
    };
  };

  outputs =
    {
      self,
      agent-skills,
      anthropic-skills,
      vercel-skills,
      my-skills,
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
              anthropic-skills
              vercel-skills
              my-skills
              ;
          }
        );
    };
}
