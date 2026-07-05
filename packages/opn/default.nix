{
  pkgs,
  pname,
  ...
}:

let
  inherit (pkgs) lib;

  opener =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "/usr/bin/open"
    else if pkgs.stdenv.hostPlatform.isLinux then
      "${pkgs.xdg-utils}/bin/xdg-open"
    else
      throw "opn does not support ${pkgs.stdenv.hostPlatform.system}";
in
pkgs.writeShellApplication {
  name = pname;

  text = ''
    exec ${lib.escapeShellArg opener} "$@"
  '';

  meta = {
    description = "Small opener wrapper for macOS open and Linux xdg-open";
    mainProgram = pname;
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
}
