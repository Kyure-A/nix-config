{
  description = "Agent Skills";

  inputs = {
    agent-skills.url = "github:Kyure-A/agent-skills-nix";
    anthropic = {
      url = "github:anthropics/skills";
      flake = false;
    };
    find-skills = {
      url = "github:vercel-labs/skills";
      flake = false;
    };
    jev-cu = {
      url = "github:Sac-Y/Jev-cu/52d32ac24e2cea29c63d9d7c4bd6d4c401111f56";
      flake = false;
    };
    natural-japanese = {
      url = "github:coji/natural-japanese";
      flake = false;
    };
  };

  outputs =
    {
      self,
      agent-skills,
      anthropic,
      find-skills,
      jev-cu,
      natural-japanese,
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
              jev-cu
              natural-japanese
              ;
          }
        );
    };
}
