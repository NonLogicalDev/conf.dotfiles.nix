{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Split Git into small files because the settings and alias maps are dense.
  # This file is the composition point: it decides what Git owns, while sibling
  # cfg-* files explain individual behavior.
  aliases = import ./cfg-aliases.nix;
  ignorePatterns = import ./cfg-ignore-patterns.nix;
  settings = import ./cfg-settings.nix { inherit config lib pkgs; };
  stgitAliases = import ./cfg-aliases-stgit.nix { inherit lib pkgs; };
in
{
  # Keep command dependencies beside the aliases/config that call them. `gh`
  # backs one credential helper, while `stgit` backs the patch-stack aliases in
  # `alias` and `stgit.alias`.
  home.packages = [
    pkgs.gh
    pkgs.stgit
  ];

  programs.unmanaged.git = {
    enable = true;

    # Only the XDG global config exists today. Keeping one include site avoids
    # reading multi-valued settings, such as credential helpers, twice.
    includeTargets = [ ".config/git/config" ];
  };

  programs.git = {
    # Durable Git config still flows through Home Manager. The unmanaged Git
    # bridge decides how that generated text reaches conventional Git files.
    ignores = ignorePatterns;

    settings = [
      settings
      {
        alias = aliases;
        "stgit.alias" = stgitAliases;
      }
    ];
  };
}
