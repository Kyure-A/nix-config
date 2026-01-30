{ inputs, ... }:
let
  username = "kyre";
in
{
  imports = [
    ../../modules/nixos
    inputs.nixos-wsl.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
  ];

  wsl = {
    enable = true;
    defaultUser = username;
  };

  home-manager = {
    users.${username} = import ./users/kyre/home-configuration.nix;
  };
}
