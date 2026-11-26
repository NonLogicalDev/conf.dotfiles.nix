{
  inputs,
  pkgs,
  ...
}:

let
  # Load this repo's packages against the same nixpkgs instance that Home
  # Manager is using for this profile. That avoids mixing two package sets when
  # installing small local utilities such as `opn`.
  selfPackages = inputs.self.mkPackagesFor pkgs;

in
{
  # `shZsh` contains the zsh implementation details. This parent module is
  # for shell-adjacent tools and cross-shell policy.
  imports = [
    ./common.nix
    ./shBash
    ./shFish
    ./shZsh
  ];

  # Small local commands that should exist as real executables, not aliases or
  # zsh functions. `opn` is packaged under `packages/opn`.
  home.packages = [
    pkgs.dnsutils
    selfPackages.opn
  ];

}
