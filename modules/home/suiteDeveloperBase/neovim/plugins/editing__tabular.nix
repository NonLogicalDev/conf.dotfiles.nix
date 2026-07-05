{ pkgs, ... }:

{
  # Manual text alignment for ad-hoc tables, assignments, and config files.
  # Small old Vim plugin, but still useful and low maintenance.
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.tabular ];
}
