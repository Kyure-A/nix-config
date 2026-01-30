{ inputs, ... }:
let
  username = "kyre";
in
{
  imports = [
    ../../modules/nixos
    ./hardware-configurations.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    users.${username} = import ./users/kyre/home-configuration.nix;
  };
}
