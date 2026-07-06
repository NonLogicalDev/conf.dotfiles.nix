{ ... }:

{
  # `core` is the small Home Manager base every profile can import before it
  # chooses a larger suite. Keep it boring: framework glue, migration bridges,
  # and state version only. Tool opinions belong in suites such as
  # `suiteDeveloperBase`, not here.
  imports = [
    ./pkgUnmanagedBash.nix
    ./pkgUnmanagedFish.nix
    ./pkgUnmanagedGit.nix
    ./pkgUnmanagedZsh.nix
  ];

  # Let Home Manager manage itself for profiles that are activated outside a
  # larger NixOS/nix-darwin system switch. This keeps standalone HM profiles and
  # Darwin-integrated profiles using the same base module.
  programs.home-manager.enable = true;

  # Home Manager state version is intentionally pinned at the migration start
  # line. Bump only when intentionally accepting changed HM defaults.
  home.stateVersion = "25.05";
}
