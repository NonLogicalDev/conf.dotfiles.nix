{ pkgs }:

pkgs.mkShell {
  packages = [
    pkgs.nil
    pkgs.nixfmt
    pkgs.statix
  ];
}
