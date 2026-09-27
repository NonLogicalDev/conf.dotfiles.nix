{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # Login shells run /etc/zprofile's path_helper before this initialization.
  # Non-login shells need the same tools without inheriting a terminal session.
  shellEnvironment = ''
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv zsh)"
    fi
    if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    # The installer guards repeated sourcing; restore precedence even when
    # Homebrew or macOS reordered an inherited PATH before this hook ran.
    typeset -gU path
    path=("$HOME/.nix-profile/bin" /nix/var/nix/profiles/default/bin $path)
  '';
in
{
  programs.jujutsu = {
    package = inputs.nixpkgs-jujutsu.legacyPackages.${pkgs.stdenv.hostPlatform.system}.jujutsu;
    # Preserve the effective local identity, which differs from Git's identity.
    settings.user.email = lib.mkForce "oleg@nonlogical.net";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.home.homeDirectory}/.bun/bin"
    "${config.home.homeDirectory}/.lmstudio/bin"
  ];

  programs.zsh = {
    # Home Manager changes ZDOTDIR, so the former ~/.zprofile no longer runs.
    envExtra = ''
      if [[ ! -o login ]]; then
        ${shellEnvironment}
      fi
    '';
    profileExtra = shellEnvironment;
  };

  # Retain the database filename declared by the previous local sync service.
  launchd.agents.atuin-server.config.EnvironmentVariables.ATUIN_DB_URI =
    lib.mkForce "sqlite://${config.xdg.dataHome}/atuin/atuin-server.db";
}
