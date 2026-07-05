{
  config,
  lib,
  pkgs,
  ...
}:

let
  atuinServer = rec {
    svcLaunchdDomain = "user";
    svcLaunchdLabel = "org.nix-community.home.atuin-server";
    svcSystemdUnitName = "atuin-server.service";
    svcNetworkHost = "127.0.0.1";
    svcNetworkPort = "45654";
    svcDirectoryData = "${config.xdg.dataHome}/atuin";
    svcDirectoryLaunchdLog = "${config.home.homeDirectory}/Library/Logs/atuin";
    svcDatabaseUri = "sqlite://${svcDirectoryData}/server.db";
    svcEnvironment = {
      ATUIN_DB_URI = svcDatabaseUri;
      ATUIN_OPEN_REGISTRATION = "true";
      RUST_LOG = "info,atuin_server=debug";
    };
    svcCmdStart = [
      (lib.getExe config.programs.atuin.package)
      "server"
      "start"
      "--host"
      svcNetworkHost
      "--port"
      svcNetworkPort
    ];
  };

  # These commands control the local user service. They are host-user
  # operational helpers, not reusable repo packages, so they stay local to this
  # Home Manager profile.
  atuinServerToolsLaunchd =
    let
      atuinServerToolLaunchdUp = pkgs.writeShellApplication {
        name = "atuin-server-up";

        text = ''
          user_id="$(/usr/bin/id -u)"
          launchd_domain="${atuinServer.svcLaunchdDomain}/$user_id"
          launchd_label="${atuinServer.svcLaunchdLabel}"
          launchd_plist="$HOME/Library/LaunchAgents/$launchd_label.plist"

          if [ ! -r "$launchd_plist" ]; then
            echo >&2 "Missing launchd plist: $launchd_plist"
            echo >&2 "Run Home Manager activation before starting the Atuin server."
            exit 1
          fi

          if ! /bin/launchctl print "$launchd_domain/$launchd_label" >/dev/null 2>&1; then
            /bin/launchctl bootstrap "$launchd_domain" "$launchd_plist"
          fi

          /bin/launchctl kickstart -k "$launchd_domain/$launchd_label"
          /bin/launchctl print "$launchd_domain/$launchd_label"
        '';
      };

      atuinServerToolLaunchdDown = pkgs.writeShellApplication {
        name = "atuin-server-down";

        text = ''
          user_id="$(/usr/bin/id -u)"
          launchd_domain="${atuinServer.svcLaunchdDomain}/$user_id"
          launchd_label="${atuinServer.svcLaunchdLabel}"

          if ! /bin/launchctl print "$launchd_domain/$launchd_label" >/dev/null 2>&1; then
            echo "$launchd_label is not loaded"
            exit 0
          fi

          /bin/launchctl bootout "$launchd_domain/$launchd_label"
        '';
      };
    in
    pkgs.symlinkJoin {
      name = "atuin-server-tools";
      paths = [
        atuinServerToolLaunchdUp
        atuinServerToolLaunchdDown
      ];
    };

  atuinServerToolsSystemd =
    let
      atuinServerCmdSystemctl = config.systemd.user.systemctlPath;

      atuinServerToolSystemdUp = pkgs.writeShellApplication {
        name = "atuin-server-up";

        text = ''
          systemd_unit="${atuinServer.svcSystemdUnitName}"

          if ! ${atuinServerCmdSystemctl} --user cat "$systemd_unit" >/dev/null 2>&1; then
            echo >&2 "Missing systemd user unit: $systemd_unit"
            echo >&2 "Run Home Manager activation before starting the Atuin server."
            exit 1
          fi

          ${atuinServerCmdSystemctl} --user start "$systemd_unit"
          ${atuinServerCmdSystemctl} --user status --no-pager "$systemd_unit"
        '';
      };

      atuinServerToolSystemdDown = pkgs.writeShellApplication {
        name = "atuin-server-down";

        text = ''
          systemd_unit="${atuinServer.svcSystemdUnitName}"

          if ! ${atuinServerCmdSystemctl} --user cat "$systemd_unit" >/dev/null 2>&1; then
            echo "$systemd_unit is not installed"
            exit 0
          fi

          ${atuinServerCmdSystemctl} --user stop "$systemd_unit"
        '';
      };
    in
    pkgs.symlinkJoin {
      name = "atuin-server-tools";
      paths = [
        atuinServerToolSystemdUp
        atuinServerToolSystemdDown
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
      atuinServerToolsLaunchd
    ])
    ++ (lib.optionals (pkgs.stdenv.isLinux && config.systemd.user.enable) [
      atuinServerToolsSystemd
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
    domain = lib.mkDefault atuinServer.svcLaunchdDomain;
    config = {
      ProgramArguments = atuinServer.svcCmdStart;
      EnvironmentVariables = atuinServer.svcEnvironment;
      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
      ProcessType = "Background";
      RunAtLoad = true;
      StandardOutPath = "${atuinServer.svcDirectoryLaunchdLog}/launchd-stdout.log";
      StandardErrorPath = "${atuinServer.svcDirectoryLaunchdLog}/launchd-stderr.log";
    };
  };

  systemd.user.services.atuin-server = lib.mkIf (pkgs.stdenv.isLinux && config.systemd.user.enable) {
    Unit = {
      Description = "Atuin local sync server";
    };

    Service = {
      ExecStart = lib.escapeShellArgs atuinServer.svcCmdStart;
      Environment = lib.mapAttrsToList (name: value: "${name}=${value}") atuinServer.svcEnvironment;
      Restart = "on-failure";
      RestartSec = "5s";
    };

    Install.WantedBy = [ "default.target" ];
  };
}
