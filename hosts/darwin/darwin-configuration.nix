{ inputs, pkgs, ... }:
let
  username = "kyre";
in
{
  imports = [
    ../../modules/darwin
    inputs.home-manager.darwinModules.home-manager
  ];

  nixpkgs.overlays = [
    inputs.brew-nix.overlays.default
    inputs.bun2nix.overlays.default
    inputs.llm-agents.overlays.default
    (import ../../overlays/karabiner-elements.nix)
    (import ../../overlays/lm-studio.nix)
    (import ../../overlays/unity-hub.nix)
    (import ../../overlays/rekordbox.nix)
    inputs.rust-overlay.overlays.default
    inputs.fenix.overlays.default
    inputs.rustowl-flake.overlays.default
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.${username}.home = "/Users/${username}";

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs pkgs; };
    users.${username} = import ./users/kyre/home-configuration.nix;
  };
}
