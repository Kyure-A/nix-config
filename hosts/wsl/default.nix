{
  self,
  nixpkgs,
  home-manager,
  nixos-wsl,
  overlays,
  skills-config,
  emacs-d,
}:
let
  username = "kyre";
  system = "x86_64-linux";
in
{
  wsl = nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      ../../modules/nixos
      nixos-wsl.nixosModules.default
      home-manager.nixosModules.home-manager
      {
        home-manager.useUserPackages = true;
        home-manager.users."${username}" = import ../../home {
          inherit
            system
            nixpkgs
            overlays
            emacs-d
            ;
          inputs = { inherit skills-config; };
        };
      }
    ];
    specialArgs = { isWsl = true; };
  };
}
