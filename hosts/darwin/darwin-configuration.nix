{ inputs, ... }:
let
  username = "kyre";
in
{
  imports = [
    ../../modules/darwin
    inputs.home-manager.darwinModules.home-manager
  ];

  users.users.${username}.home = "/Users/${username}";

  home-manager = {
    users.${username} = import ./users/kyre/home-configuration.nix;
  };
}
