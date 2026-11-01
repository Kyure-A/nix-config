{ inputs, ... }:
{
  imports = [ inputs.dsh-config.homeManagerModules.default ];

  programs.dsh = {
    enable = true;
    tailnetHost = inputs.dsh-config.lib.network.fqdn "lelouch";
    settingsSync.remote.host = "avalon";
    instructionsFile = ../../AGENTS.md;
  };
}
