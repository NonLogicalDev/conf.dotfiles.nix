{
  pkgs,
  ...
}:

let
  # These commands are host-user operational helpers, not reusable repo
  # packages. Keeping them local to the Atuin Home Manager profile makes that
  # ownership explicit while still installing real executables.
  atuinServerTools =
    let
      image = "ghcr.io/atuinsh/atuin:v18.10.0";
      containerName = "atuin-server";
      hostAddress = "127.0.0.1";
      hostPort = "45654";
      containerPort = "8888";
      dataSubdir = ".local/share/atuin";
      databaseUri = "sqlite:///data/atuin-server.db";
      rustLog = "info,atuin_server=debug";

      atuinServerUp = pkgs.writeShellApplication {
        name = "atuin-server-up";
        runtimeInputs = [ pkgs.docker-client ];

        text = ''
          container_name="''${ATUIN_SERVER_CONTAINER_NAME:-${containerName}}"
          image="''${ATUIN_SERVER_IMAGE:-${image}}"
          host_address="''${ATUIN_SERVER_HOST_ADDRESS:-${hostAddress}}"
          host_port="''${ATUIN_SERVER_HOST_PORT:-${hostPort}}"
          container_port="''${ATUIN_SERVER_CONTAINER_PORT:-${containerPort}}"
          data_dir="''${ATUIN_SERVER_DATA_DIR:-$HOME/${dataSubdir}}"
          open_registration="''${ATUIN_SERVER_OPEN_REGISTRATION:-true}"
          database_uri="''${ATUIN_SERVER_DB_URI:-${databaseUri}}"
          rust_log="''${ATUIN_SERVER_RUST_LOG:-${rustLog}}"

          mkdir -p "$data_dir"

          if docker container inspect "$container_name" >/dev/null 2>&1; then
            if [ "$(docker inspect --format '{{.State.Running}}' "$container_name")" = "true" ]; then
              echo "$container_name is already running"
              exit 0
            fi

            docker start "$container_name"
            exit 0
          fi

          docker run \
            --detach \
            --name "$container_name" \
            --restart unless-stopped \
            --publish "$host_address:$host_port:$container_port" \
            --volume "$data_dir:/data" \
            --env ATUIN_HOST=0.0.0.0 \
            --env "ATUIN_PORT=$container_port" \
            --env "ATUIN_OPEN_REGISTRATION=$open_registration" \
            --env "ATUIN_DB_URI=$database_uri" \
            --env "RUST_LOG=$rust_log" \
            "$image" \
            server start
        '';
      };

      atuinServerDown = pkgs.writeShellApplication {
        name = "atuin-server-down";
        runtimeInputs = [ pkgs.docker-client ];

        text = ''
          container_name="''${ATUIN_SERVER_CONTAINER_NAME:-${containerName}}"

          if ! docker container inspect "$container_name" >/dev/null 2>&1; then
            echo "$container_name does not exist"
            exit 0
          fi

          if [ "$(docker inspect --format '{{.State.Running}}' "$container_name")" = "true" ]; then
            docker stop "$container_name"
          fi

          docker rm "$container_name"
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

    # The profile already uses zsh as the active interactive shell. Fish had an
    # old Dotter `atuin init fish` snippet, but fish itself is not being migrated
    # in this slice.
    enableZshIntegration = true;
    enableBashIntegration = false;
    enableFishIntegration = false;

    # The existing `~/.config/atuin/config.toml` is a Dotter symlink. Taking
    # ownership here lets Home Manager replace that symlink during activation.
    forceOverwriteSettings = true;

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

  # Local server operation is exposed as explicit commands instead of migrated
  # Dotter helper files. This preserves the useful behavior while keeping the
  # Atuin client config declarative and compact.
  home.packages = [
    atuinServerTools
  ];
}
