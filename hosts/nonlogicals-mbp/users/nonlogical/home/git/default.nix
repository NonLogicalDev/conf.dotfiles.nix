{
  lib,
  pkgs,
  ...
}:

let
  aliases = import ./cfg-aliases.nix;
  ignorePatterns = import ./cfg-ignore-patterns.nix;
  settings = import ./cfg-settings.nix { inherit lib pkgs; };
  stgitAliases = import ./cfg-aliases-stgit.nix;
in
{
  home.packages = [
    pkgs.gh
  ];

  programs.unmanaged.git = {
    enable = true;

    # Only the XDG global config exists today. Keeping one include site avoids
    # reading multi-valued settings, such as credential helpers, twice.
    includeTargets = [ ".config/git/config" ];
  };

  programs.git = {
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
