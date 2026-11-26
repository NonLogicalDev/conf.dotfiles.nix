{ pkgs, ... }:

let
  zellijConfig = builtins.readFile ./config.kdl;
  roomPlugin = pkgs.fetchurl {
    url = "https://github.com/rvcas/room/releases/download/v1.2.1/room.wasm";
    hash = "sha256-kLSDpAt2JGj7dYYhYFh6BfvtzVwTrcs+0jHwG/nActE=";
  };
in
{
  programs.zellij = {
    enable = true;
    extraConfig = zellijConfig;
  };

  xdg.configFile."zellij/plugins/room.wasm" = {
    source = roomPlugin;
  };
}
