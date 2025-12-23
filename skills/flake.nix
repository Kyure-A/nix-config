{
  description = "Agent Skills";

  inputs = {
    agent-skills.url = "github:Kyure-A/agent-skills-nix";
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };
  };

  outputs = { self, agent-skills, anthropic-skills, ... }:
    {
      homeManagerModules.default =
        import ./default.nix { inherit agent-skills anthropic-skills; };
    };
}
