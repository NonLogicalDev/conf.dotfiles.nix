{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.packages = [
    pkgs.ripgrep
  ];

  home.stateVersion = "25.05";
}

