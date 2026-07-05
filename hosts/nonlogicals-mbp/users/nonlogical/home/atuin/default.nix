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
      # Local sync server, currently described by the companion compose file
      # below. Secrets and account/session material remain in Atuin's data dirs.
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

  # These are not Atuin client settings; they are local tooling for running the
  # personal sync server. Keep them as small companion files instead of trying to
  # force them through `programs.atuin.settings`.
  xdg.configFile = {
    "atuin/Justfile" = {
      source = ./Justfile;
      force = true;
    };

    "atuin/compose.yml" = {
      source = ./compose.yml;
      force = true;
    };
  };
}
