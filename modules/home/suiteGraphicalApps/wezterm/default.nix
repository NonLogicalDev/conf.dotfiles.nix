{
  config,
  lib,
  pkgs,
  ...
}:

let
  settings = config.dotfiles.suites.graphicalApps.wezterm;
  defaultRemoteDomain =
    if settings.defaultRemoteDomain == null then
      "nil"
    else
      builtins.toJSON settings.defaultRemoteDomain;
  weztermConfig = builtins.replaceStrings [ "__DOTFILES_DEFAULT_REMOTE_DOMAIN__" ] [
    defaultRemoteDomain
  ] (builtins.readFile ./wezterm.lua);
in
{
  options.dotfiles.suites.graphicalApps.wezterm.defaultRemoteDomain = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Optional SSH domain used when no remote domain environment override is set.";
  };

  config = lib.mkIf pkgs.stdenv.isDarwin {
    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;
      extraConfig = weztermConfig;
    };

    home.file.".wezterm.lua".text = weztermConfig;
  };
}
