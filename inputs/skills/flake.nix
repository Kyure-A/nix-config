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
              natural-japanese
              ;
          }
        );
    };
}
