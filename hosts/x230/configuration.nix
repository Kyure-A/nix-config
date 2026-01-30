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

  nixpkgs.overlays = [
    inputs.bun2nix.overlays.default
    inputs.llm-agents.overlays.default
    inputs.rust-overlay.overlays.default
    inputs.fenix.overlays.default
    inputs.rustowl-flake.overlays.default
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs pkgs; };
    users.${username} = import ./users/kyre/home-configuration.nix;
  };
}
