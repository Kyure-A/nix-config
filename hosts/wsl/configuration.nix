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

  nixpkgs.hostPlatform = "x86_64-linux";

  wsl = {
    enable = true;
    defaultUser = username;
  };

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs; };
    users.${username} = import ./users/kyre/home-configuration.nix;
  };
}
