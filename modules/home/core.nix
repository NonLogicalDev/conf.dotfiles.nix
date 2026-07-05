{ ... }:

{
  imports = [
    ./programs/unmanaged/bash.nix
    ./programs/unmanaged/git.nix
    ./programs/unmanaged/zsh.nix
  ];

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
