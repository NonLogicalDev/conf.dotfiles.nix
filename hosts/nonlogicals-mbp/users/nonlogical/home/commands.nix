{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  commands = (inputs.self.mkPackagesFor pkgs).developer-commands;
  gitUtils = lib.getExe' commands "git-utils";
  stgUtils = lib.getExe' commands "stg-utils";
in
{
  home.packages = [ commands ];

  # Preserve the existing machine-local exclusion when HM owns git/ignore.
  programs.git.ignores = [ "**/.claude/settings.local.json" ];

  # These aliases depend on the packaged personal commands. Keep them with
  # this host's enablement instead of making the shared Git suite require them.
  programs.git.settings = [
    {
      alias = {
        ctx = "!${gitUtils} git-ctx -q ctx/";
        addu = "!${gitUtils} git-checked-add-update";
      };
      "stgit.alias" = {
        patch-path = "!${stgUtils} files";
        pp = "!${stgUtils} files";
        t = "!${stgUtils} patch-info";
        pn = "!${stgUtils} patch-new";
        pi = "!${stgUtils} push-interactive";
        spilli = "!${stgUtils} spill-interactive";
        pushm = "!${stgUtils} push-set";
        mpush = "!${stgUtils} push-set";
        rstash = "!${gitUtils} stg-rstash";
      };
    }
  ];
}
