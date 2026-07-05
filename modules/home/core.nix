{ ... }:

{
  imports = [
    ./programs/unmanaged
  ];

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
