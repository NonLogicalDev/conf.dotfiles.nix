{ ... }:

{
  imports = [
    ./pkgUnmanagedBash.nix
    ./pkgUnmanagedGit.nix
    ./pkgUnmanagedZsh.nix
  ];

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
