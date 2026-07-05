{ pkgs, ... }:

{
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.vim-indent-object ];
}
