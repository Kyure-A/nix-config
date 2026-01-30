{ inputs, pkgs, ... }:
let
  username = "kyre";
in
{
  imports = [
    ../../modules/nixos
    ./hardware-configurations.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs pkgs; };
    users.${username} = import ./users/kyre/home-configuration.nix;
  };
}
