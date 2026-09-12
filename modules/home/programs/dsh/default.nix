{
  config,
  lib,
  pkgs,
  ...
}:
let
  rawDsh = pkgs.callPackage ../../../../inputs/dsh { };
  yaml = pkgs.formats.yaml { };
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
  patch = yaml.generate "dsh-cordis.patch.yml" [
    {
      id = "agent-default-model";
      config = {
        provider = "ollama";
        inherit model;
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
  # Use the pinned upstream coding preset and connect Blender only for a
  # Blender session, avoiding 28 extra tool schemas in every local request.
  blenderPreset = pkgs.runCommand "dsh-blender-preset" { } ''
    mkdir -p $out
    cp ${rawDsh}/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/dsh-agent-presets/presets/standard/agent.cordis.yml $out/agent.cordis.yml
    chmod u+w $out/agent.cordis.yml
    # Append sequence items inside the existing YAML document.
    sed '/^%YAML /d; /^---$/d' ${blenderTools} >> $out/agent.cordis.yml
    cat > $out/preset.yml <<'YAML'
    name: Blender
    description: Clothing creation, scene inspection, and Blender automation with the shared project skills.
    order: 10
    YAML
  '';
  initialSettings = yaml.generate "dsh-initial-settings.yaml" {
    agent-default-model = {
      provider = "ollama";
      inherit model;
      reasoningEffort = "medium";
    };
  };
  web = pkgs.writeShellApplication {
    name = "dsh-web";
    runtimeInputs = [
      dsh
      pkgs.curl
      pkgs.coreutils
    ];
    text =
      if pkgs.stdenv.isDarwin then
        ''
          /bin/launchctl kickstart "gui/$(/usr/bin/id -u)/org.nix-community.home.dsh-web"
          for _attempt in $(seq 1 60); do
            if curl --silent --output /dev/null http://127.0.0.1:3080/; then
              exec /usr/bin/osascript -l JavaScript ${./open-web.js} ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh/web.log"}
            fi
            sleep 1
          done
          echo "DSH did not become ready. Check ~/.local/state/dsh/web.log." >&2
          exit 1
        ''
      else
        ''
          exec dsh web "$@"
        '';
  };
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
  ++ lib.optionals pkgs.stdenv.isDarwin [ webApp ];
  home.file = {
    ".dsh/AGENTS.md".source = ../../AGENTS.md;
    ".dsh/cordis.patch.yml".source = patch;
    ".dsh/.agent-presets/chat" = {
      source = ./chat;
      recursive = true;
    };
    ".dsh/.agent-presets/blender" = lib.mkIf pkgs.stdenv.isDarwin {
      source = blenderPreset;
      recursive = true;
    };
  };
  # User model/UI changes remain writable; Nix supplies the baseline above.
  home.activation.dshState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/.dsh"} ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh"}
    run chmod 700 ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh"}
    run touch ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh/web.log"}
    run chmod 600 ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/dsh/web.log"}
    if [ ! -e ${lib.escapeShellArg "${config.home.homeDirectory}/.dsh/settings.yaml"} ]; then
      run install -m 600 ${initialSettings} ${lib.escapeShellArg "${config.home.homeDirectory}/.dsh/settings.yaml"}
    fi
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
}
