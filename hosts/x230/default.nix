{
  self,
  nixpkgs,
  home-manager,
  overlays,
  emacs-d,
}:
let
  username = "kyre";
  system = "x86_64-linux";
  emacs-config = emacs-d.packages.${system}.default;
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
            emacs-config
            ;
        };
      }
    ];
  };
}
