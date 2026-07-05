{
  config,
  lib,
  pkgs,
  ...
}:

let
  atuinServer = rec {
    label = "org.nix-community.home.atuin-server";
    systemdUnit = "atuin-server.service";
    host = "127.0.0.1";
    port = "45654";
    dataDir = "${config.xdg.dataHome}/atuin";
    databaseUri = "sqlite://${dataDir}/server.db";
    logDir = "${config.home.homeDirectory}/Library/Logs/atuin";
    environment = {
      ATUIN_DB_URI = databaseUri;
      ATUIN_OPEN_REGISTRATION = "true";
      RUST_LOG = "info,atuin_server=debug";
    };
    command = [
      (lib.getExe config.programs.atuin.package)
      "server"
      "start"
      "--host"
      host
      "--port"
      port
    ];
  };

  # These commands control the local user service. They are host-user
  # operational helpers, not reusable repo packages, so they stay local to this
  # Home Manager profile.
  atuinServerLaunchdTools =
    let
      atuinServerLaunchdUp = pkgs.writeShellApplication {
        name = "atuin-server-up";

        text = ''
          uid="$(/usr/bin/id -u)"
          domain="user/$uid"
          label="${atuinServer.label}"
          plist="$HOME/Library/LaunchAgents/$label.plist"

          if [ ! -r "$plist" ]; then
            echo >&2 "Missing launchd plist: $plist"
            echo >&2 "Run Home Manager activation before starting the Atuin server."
            exit 1
          fi

          if ! /bin/launchctl print "$domain/$label" >/dev/null 2>&1; then
            /bin/launchctl bootstrap "$domain" "$plist"
          fi

          /bin/launchctl kickstart -k "$domain/$label"
          /bin/launchctl print "$domain/$label"
        '';
      };

      atuinServerLaunchdDown = pkgs.writeShellApplication {
        name = "atuin-server-down";

        text = ''
          uid="$(/usr/bin/id -u)"
          domain="user/$uid"
          label="${atuinServer.label}"

          if ! /bin/launchctl print "$domain/$label" >/dev/null 2>&1; then
            echo "$label is not loaded"
            exit 0
          fi

          /bin/launchctl bootout "$domain/$label"
        '';
      };
    in
    pkgs.symlinkJoin {
      name = "atuin-server-tools";
      paths = [
        atuinServerLaunchdUp
        atuinServerLaunchdDown
      ];
    };

  atuinServerSystemdTools =
    let
      atuinServerSystemdUp = pkgs.writeShellApplication {
        name = "atuin-server-up";

        text = ''
          unit="${atuinServer.systemdUnit}"

          if ! systemctl --user cat "$unit" >/dev/null 2>&1; then
            echo >&2 "Missing systemd user unit: $unit"
            echo >&2 "Run Home Manager activation before starting the Atuin server."
            exit 1
          fi

          systemctl --user enable --now "$unit"
          systemctl --user status --no-pager "$unit"
        '';
      };

      atuinServerSystemdDown = pkgs.writeShellApplication {
        name = "atuin-server-down";

        text = ''
          unit="${atuinServer.systemdUnit}"

          if ! systemctl --user cat "$unit" >/dev/null 2>&1; then
            echo "$unit is not installed"
            exit 0
          fi

          systemctl --user disable --now "$unit"
        '';
      };
    in
    pkgs.symlinkJoin {
      name = "atuin-server-tools";
      paths = [
        atuinServerSystemdUp
        atuinServerSystemdDown
      ];
    };
in
{
  # Atuin is migrated early because its Dotter config is mostly generated
  # comments plus a small set of real preferences. Home Manager can express
  # those preferences directly, so we avoid copying the whole generated TOML.
  programs.atuin = {
    enable = true;

    settings = {
      # Preserve the behavioral fact that Atuin syncs against a local server.
      # How that server is launched is operational plumbing, not client config.
      sync_address = "http://127.0.0.1:45654";

      # Keep the shell up-key scoped to the current session instead of searching
      # all global history.
      filter_mode_shell_up_key_binding = "session";

      # Escape should leave the typed query in the shell rather than replacing it
      # with the original command.
      exit_mode = "return-query";

      # Require an explicit accept/edit decision from the Atuin UI before a
      # command is executed.
      enter_accept = false;

      stats = {
        # Preserve the existing command grouping that makes Atuin stats useful
        # for common developer CLIs with meaningful subcommands.
        common_subcommands = [
          "apt"
          "cargo"
          "composer"
          "dnf"
          "docker"
          "git"
          "go"
          "ip"
          "kubectl"
          "nix"
          "nmcli"
          "npm"
          "pecl"
          "pnpm"
          "podman"
          "port"
          "systemctl"
          "tmux"
          "yarn"
        ];

        # Treat `sudo foo` as `foo` for stats.
        common_prefix = [ "sudo" ];
      };

      sync = {
        # Keep Atuin's sync-v2 record mode enabled.
        records = true;
      };
    };
  };

  # Local server operation is exposed as explicit commands backed by the native
  # per-user service manager for each OS: launchd on macOS, systemd on Linux.
  home.packages =
    (lib.optionals pkgs.stdenv.isDarwin [
      atuinServerLaunchdTools
    ])
    ++ (lib.optionals pkgs.stdenv.isLinux [
      atuinServerSystemdTools
    ]);

  # Create the mutable data directory the local server depends on without
  # hiding setup in a startup wrapper. macOS also needs a log directory because
  # launchd writes stdout/stderr to files; Linux uses the user journal.
  xdg.dataFile."atuin/.keep".text = "";
  home.file = lib.mkIf pkgs.stdenv.isDarwin {
    "Library/Logs/atuin/.keep".text = "";
  };

  launchd.agents.atuin-server = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    domain = "user";
    config = {
      ProgramArguments = atuinServer.command;
      EnvironmentVariables = atuinServer.environment;
      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
      ProcessType = "Background";
      StandardOutPath = "${atuinServer.logDir}/launchd-stdout.log";
      StandardErrorPath = "${atuinServer.logDir}/launchd-stderr.log";
    };
  };

  systemd.user.services.atuin-server = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Atuin local sync server";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      ExecStart = lib.escapeShellArgs atuinServer.command;
      Environment = lib.mapAttrsToList (name: value: "${name}=${value}") atuinServer.environment;
      Restart = "on-failure";
      RestartSec = "5s";
    };

    Install.WantedBy = [ "default.target" ];
  };
}
