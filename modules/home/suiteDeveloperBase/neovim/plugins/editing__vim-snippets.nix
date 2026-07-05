{ pkgs, ... }:

{
  # SnipMate-format snippet collection loaded by LuaSnip. Kept alongside
  # friendly-snippets because older snippets often exist only in this format.
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.vim-snippets ];
}
