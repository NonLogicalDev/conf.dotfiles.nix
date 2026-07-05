{
  config,
  lib,
  pkgs,
  ...
}:

let
  server = rec {
    label = "org.nix-community.home.atuin-server";
    host = "127.0.0.1";
    port = "45654";
    dataDir = "${config.xdg.dataHome}/atuin";
    databaseUri = "sqlite://${dataDir}/server.db";
    logDir = "${config.home.homeDirectory}/Library/Logs/atuin";
  };

  # These commands control the launchd agent. They are host-user operational
  # helpers, not reusable repo packages, so they stay local to this Home Manager
  # profile.
  atuinServerTools =
    let
      atuinServerUp = pkgs.writeShellApplication {
        name = "atuin-server-up";

        text = ''
          uid="$(/usr/bin/id -u)"
          domain="user/$uid"
          label="${server.label}"
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

      atuinServerDown = pkgs.writeShellApplication {
        name = "atuin-server-down";

        text = ''
          uid="$(/usr/bin/id -u)"
          domain="user/$uid"
          label="${server.label}"

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
        atuinServerUp
        atuinServerDown
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

  # Local server operation is exposed as explicit commands backed by a launchd
  # agent on macOS. Linux profiles can still use the shared client settings;
  # service ownership for Linux should live in a Linux-specific system layer.
  home.packages = lib.optionals pkgs.stdenv.isDarwin [
    atuinServerTools
  ];

  # Create the mutable directories the launchd job depends on without hiding
  # that setup in a startup wrapper.
  xdg.dataFile."atuin/.keep".text = "";
  home.file = lib.mkIf pkgs.stdenv.isDarwin {
    "Library/Logs/atuin/.keep".text = "";
  };

  launchd.agents.atuin-server = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    domain = "user";
    config = {
      ProgramArguments = [
        (lib.getExe config.programs.atuin.package)
        "server"
        "start"
        "--host"
        server.host
        "--port"
        server.port
      ];
      EnvironmentVariables = {
        ATUIN_DB_URI = server.databaseUri;
        ATUIN_OPEN_REGISTRATION = "true";
        RUST_LOG = "info,atuin_server=debug";
      };
      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
      ProcessType = "Background";
      StandardOutPath = "${server.logDir}/launchd-stdout.log";
      StandardErrorPath = "${server.logDir}/launchd-stderr.log";
    };
  };
}
