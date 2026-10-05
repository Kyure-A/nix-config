{
  config,
  lib,
  pkgs,
  ...
}:
let
  rawDsh = pkgs.callPackage ../../../../inputs/dsh { };
  yaml = pkgs.formats.yaml { };
  json = pkgs.formats.json { };
  dsh = pkgs.writeShellScriptBin "dsh" ''
    exec ${lib.getExe pkgs.python3} ${./launch.py} ${lib.getExe rawDsh} "$@"
  '';
  model = "hf.co/unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL";
  compat = {
    supportsStore = false;
    supportsDeveloperRole = false;
    maxTokensField = "max_tokens";
  };
  localModel = id: name: {
    inherit id name;
    input = [
      "text"
      "image"
    ];
    contextWindow = 32768;
    maxTokens = 8192;
    reasoningEfforts = {
      off = null;
      medium = "medium";
      high = "high";
    };
  };
  defaults = yaml.generate "dsh-defaults.patch.yml" [
    {
      id = "agent-default-model";
      config = {
        provider = "ollama";
        inherit model;
        reasoningEffort = "medium";
      };
    }
    {
      id = "llm-pi-ai";
      config.providers = {
        ollama = {
          displayName = "Local Ollama";
          apiKeyEnv = "OLLAMA_API_KEY";
          api = "openai-completions";
          baseURL = "http://127.0.0.1:11434/v1";
          inherit compat;
          retryPolicy = {
            mode = "normal";
            maxRetries = 1;
          };
          models = [
            (localModel model "Qwen3.8 27B UD-Q4_K_XL (local)")
            (localModel "huihui_ai/qwen3.6-abliterated:27b" "Huihui Qwen3.6 Abliterated 27B (local)")
          ];
        };
        venice = {
          displayName = "Venice";
          apiKeyEnv = "VENICE_API_KEY";
          api = "openai-completions";
          baseURL = "https://api.venice.ai/api/v1";
          compat = compat // {
            supportsReasoningEffort = false;
          };
          models = [
            {
              id = "qwen-3-6-plus";
              name = "Qwen 3.6 Plus Uncensored (Venice)";
              input = [
                "text"
                "image"
              ];
              contextWindow = 1000000;
              maxTokens = 8192;
              reasoningEfforts = false;
            }
            {
              id = "e2ee-gemma-4-26b-a4b-uncensored-p";
              name = "Gemma 4 26B TEE (Chat preset only)";
              input = [ "text" ];
              contextWindow = 64000;
              maxTokens = 4096;
              reasoningEfforts = false;
            }
          ];
        };
      };
    }
  ];
  patch = yaml.generate "dsh-cordis.patch.yml" [
    {
      id = "session-telemetry-otel";
      disabled = true;
    }
    {
      id = "session-title-llm";
      disabled = true;
    }
  ];
  blenderTools = yaml.generate "dsh-blender-tools.yml" [
    {
      id = "mcp-blender";
      name = "@deepseek-ai/dsh-mcp-client";
      config = {
        serverName = "blender";
        transport = "stdio";
        command = "${config.home.homeDirectory}/.local/share/blender-mcp/.venv/bin/blender-mcp";
        args = [ ];
        env = {
          BLENDER_HOST = "127.0.0.1";
          BLENDER_MCP_DISABLE_TELEMETRY = "1";
        };
        cwd = config.home.homeDirectory;
        toolCallTimeoutMs = 180000;
        failOnStartupError = false;
      };
    }
  ];
  chatPreset = yaml.generate "dsh-chat-preset.patch.yml" [
    {
      insert = [
        {
          id = "preset-chat";
          name = "@deepseek-ai/dsh-agent-preset";
          disabled = false;
          config = {
            id = "chat";
            name = "Chat (no tools)";
            description = "Text conversation for models without function calling, including Venice E2EE.";
            order = 20;
            plugins = [
              {
                id = "persona";
                name = "@deepseek-ai/dsh-persona";
                config = {
                  prefix = "You are a helpful assistant. This conversation has no tools.";
                  complete = true;
                  includeRuntimeContext = false;
                };
              }
              {
                id = "no-tools";
                name = "${./chat/no-tools.mjs}";
              }
            ];
          };
        }
      ];
    }
  ];
  # Bundle defaults inherit below each writable profile patch. A home-level
  # provider/model override would outrank and prevent settings edits in DSH 0.2.
  defaultsManifest = json.generate "dsh-defaults-package.json" {
    name = "@local/dsh-defaults";
    version = "0.2.0";
    private = true;
    peerDependencies."@deepseek-ai/dsh" = "0.2.0-rc.2";
    dsh.bundle.patch = [
      "./defaults.patch.yml"
      "./chat.patch.yml"
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [ "./blender.patch.yml" ];
  };
  defaultsBundle = pkgs.runCommand "dsh-defaults-bundle" { } ''
    mkdir -p $out
    cp ${defaultsManifest} $out/package.json
    cp ${defaults} $out/defaults.patch.yml
    ${lib.getExe pkgs.python3} - ${chatPreset} $out/chat.patch.yml <<'PY'
    from pathlib import Path
    import sys
    source = Path(sys.argv[1]).read_text()
    assert source.count("disabled: false") == 1, "Review the Chat preset declaration."
    source = source.replace("disabled: false", "disabled: !!js \"ctx.get('profileContext')?.name !== 'web'\"")
    Path(sys.argv[2]).write_text(source)
    PY
    ${lib.optionalString pkgs.stdenv.isDarwin ''
      ${lib.getExe pkgs.python3} ${./make-blender-preset.py} \
        ${rawDsh}/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/dsh-web-app/presets/standard.patch.yml \
        ${blenderTools} $out/blender.patch.yml
    ''}
  '';
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
  webApp = pkgs.runCommand "dsh-web-app" { } ''
    app="$out/Applications/DSH Web.app/Contents"
    mkdir -p "$app/MacOS"
    ln -s ${lib.getExe web} "$app/MacOS/dsh-web"
    cat > "$app/Info.plist" <<'PLIST'
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0"><dict>
    <key>CFBundleExecutable</key><string>dsh-web</string>
    <key>CFBundleIdentifier</key><string>moe.kyre.dsh-web</string>
    <key>CFBundleName</key><string>DSH Web</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSUIElement</key><true/>
    </dict></plist>
    PLIST
  '';
in
{
  home.packages = [
    dsh
    web
  ]
  ++ lib.optionals pkgs.stdenv.isDarwin [
    webApp
    tailnetProxy
  ];
  home.file = {
    ".dsh/AGENTS.md".source = ../../AGENTS.md;
    ".dsh/cordis.patch.yml".source = patch;
    ".dsh/node_modules/@local/dsh-defaults".source = defaultsBundle;
  };
  # User model/UI changes remain writable; Nix supplies the baseline above.
  home.activation.dshState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/.dsh"} ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh"}
    run chmod 700 ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh"}
    run touch ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh/web.log"}
    run chmod 600 ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh/web.log"}
    run ${lib.getExe pkgs.python3} ${./initialize-profiles.py} ${lib.escapeShellArg "${config.home.homeDirectory}/.dsh"}
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
      EnvironmentVariables.PATH = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
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
}
