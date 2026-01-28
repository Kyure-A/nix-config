{ pkgs }:
let
  lib = pkgs.lib;
  llmAgents = pkgs."llm-agents";
  copilot = llmAgents."copilot-language-server";
in
{
  home.packages = [ copilot ];

  home.sessionVariables = {
    COPILOT_LANGUAGE_SERVER_PATH = lib.getExe copilot;
  };
}
