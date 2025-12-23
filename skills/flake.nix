{
  description = "Agent Skills";

  inputs = {
    anthropic-skills.url = "github:anthropics/skills";
  };

  outputs = { self, anthropic-skills, ... }:
    {
      homeManagerModules.default =
        import ./home-manager.nix { inherit anthropic-skills; };
    };
}
