{ pkgs, ... }:

{
  # Adds richer text objects around quotes/brackets/separators. This preserves
  # old Vim muscle memory that is not covered by core Neovim text objects.
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.targets-vim ];
}
