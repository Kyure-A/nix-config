{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  rawDsh = import inputs.dsh-shared { inherit pkgs; };
  shared = import (inputs.dsh-shared + "/defaults.nix") { inherit pkgs; };
  json = pkgs.formats.json { };
  dsh = pkgs.writeShellScriptBin "dsh" ''
    exec ${lib.getExe pkgs.python3} ${./launch.py} ${lib.getExe rawDsh} "$@"
  '';
  settingsSync = pkgs.writeShellScriptBin "dsh-settings-sync" ''
    exec ${rawDsh}/bin/dsh-settings-sync "$@"
  '';
  settingsSyncConfig = json.generate "dsh-settings-sync.json" {
    home = "${config.home.homeDirectory}/.dsh";
    stateDir = "${config.home.homeDirectory}/.local/state/dsh/settings-sync";
    remote = {
      host = "avalon";
      command = [
        "sudo"
        "-n"
        "-u"
        "dsh"
        "/run/current-system/sw/bin/dsh-settings-sync"
        "--home"
        "/var/lib/dsh/.dsh"
        "worker"
      ];
    };
    intervalMs = 3000;
  };
  web = pkgs.writeShellApplication {
    name = "dsh-web";
    runtimeInputs = [
      dsh
      pkgs.python3
    ];
    text =
      if pkgs.stdenv.isDarwin then
        ''
          domain="gui/$(/usr/bin/id -u)"
          service="$domain/org.nix-community.home.dsh-web"
          if ! /bin/launchctl print "$service" >/dev/null 2>&1; then
            /bin/launchctl bootstrap "$domain" ${lib.escapeShellArg "${config.home.homeDirectory}/Library/LaunchAgents/org.nix-community.home.dsh-web.plist"}
          fi
          /bin/launchctl kickstart "$service"
          exec ${lib.getExe pkgs.python3} ${./open-web.py} \
            ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh/web.log"} ${./open-web.js}
        ''
      else
        ''
          exec dsh web "$@"
        '';
  };
  tailnetProxy = pkgs.writeShellScriptBin "dsh-tailnet-proxy" ''
    exec ${lib.getExe pkgs.nodejs_24} ${./tailnet-proxy.mjs} "$@"
  '';
  desktopApp = pkgs.callPackage ./desktop { };

in
{
  home.packages = [
    dsh
    web
    settingsSync
  ]
  ++ lib.optionals pkgs.stdenv.isDarwin [
    desktopApp
    tailnetProxy
  ];
  home.file = {
    ".config/dsh/settings-sync.json".source = settingsSyncConfig;
  };
  # User model/UI changes remain writable; Nix supplies the baseline above.
  home.activation.dshState = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/.dsh"} ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh"}
    run chmod 700 ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh"}
    run touch ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh/web.log"}
    run chmod 600 ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh/web.log"}
    run touch ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh/settings-sync.log"}
    run chmod 600 ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh/settings-sync.log"}
    run ${lib.getExe pkgs.python3} ${inputs.dsh-shared}/initialize.py ${lib.escapeShellArg "${config.home.homeDirectory}/.dsh"} \
      ${shared.bundle} \
      ${rawDsh}/lib/node_modules/@deepseek-ai/dsh/node_modules/@jcy2387/dsh-codex-provider \
      ${shared.patch} \
      ${rawDsh}/lib/node_modules/@deepseek-ai/dsh/node_modules/dsh-purge-community
    run ${lib.getExe pkgs.python3} ${./initialize-profiles.py} ${lib.escapeShellArg "${config.home.homeDirectory}/.dsh"} ${../../AGENTS.md}
  '';
  launchd.agents.dsh-web = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        (lib.getExe dsh)
        "web"
        "--no-open"
        "--port"
        "3080"
      ];
      WorkingDirectory = config.home.homeDirectory;
      EnvironmentVariables = {
        PATH = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        DSH_BASE = "${rawDsh}/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai";
      };
      Umask = 63;
      RunAtLoad = true;
      KeepAlive.SuccessfulExit = false;
      ThrottleInterval = 30;
      ProcessType = "Interactive";
      StandardOutPath = "${config.home.homeDirectory}/.local/state/dsh/web.log";
      StandardErrorPath = "${config.home.homeDirectory}/.local/state/dsh/web.log";
    };
  };
  # Tailscale Serve owns HTTPS and tailnet access. DSH keeps its existing
  # loopback listener and credential store; this proxy supplies browser auth.
  launchd.agents.dsh-tailnet-proxy = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        (lib.getExe tailnetProxy)
      ];
      EnvironmentVariables = {
        DSH_TAILNET_HOST = "lelouch.tail1afda.ts.net";
        DSH_PROXY_PORT = "3081";
        DSH_WEB_LOG = "${config.home.homeDirectory}/.local/state/dsh/web.log";
      };
      WorkingDirectory = config.home.homeDirectory;
      Umask = 63;
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/.local/state/dsh/tailnet-proxy.log";
      StandardErrorPath = "${config.home.homeDirectory}/.local/state/dsh/tailnet-proxy.log";
    };
  };
  launchd.agents.dsh-settings-sync = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        (lib.getExe settingsSync)
        "--config"
        "${config.home.homeDirectory}/.config/dsh/settings-sync.json"
        "watch"
      ];
      WorkingDirectory = config.home.homeDirectory;
      EnvironmentVariables.PATH = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      Umask = 63;
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/.local/state/dsh/settings-sync.log";
      StandardErrorPath = "${config.home.homeDirectory}/.local/state/dsh/settings-sync.log";
    };
  };
}
