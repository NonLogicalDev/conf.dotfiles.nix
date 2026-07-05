{ pkgs, ... }:

{
  # Classic surround/change/delete surrounding delimiters. This is core editing
  # muscle memory and intentionally stays small.
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.vim-surround ];
}
