{
  self,
  nixpkgs,
  home-manager,
  overlays,
  skills-config,
  emacs-d,
}:
let
  username = "kyre";
  system = "x86_64-linux";
in
{
  x230 = nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      ../../modules/nixos
      ./hardware-configurations.nix
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
    specialArgs = { isWsl = false; };
  };
}
