{
  self,
  nixpkgs,
  home-manager,
  nix-darwin,
  overlays,
  emacs-d,
}:
let
  system = "aarch64-darwin";
  username = "kyre";
  configuration =
    { ... }:
    {
      users.users.${username}.home = "/Users/${username}";
    };
  emacs-config = emacs-d.packages.${system}.default;
in
{
  darwin = nix-darwin.lib.darwinSystem {
    inherit system;
    specialArgs = { inherit username; };
    modules = [
      configuration
      ../../modules/darwin
      home-manager.darwinModules.home-manager
      {
        home-manager.useUserPackages = true;
        home-manager.users."${username}" = import ../../home {
          inherit
            system
            nixpkgs
            overlays
            emacs-d
            emacs-config
            ;
        };
      }
    ];
  };
}
