{ pkgs, ... }:

{
  # Community snippet collection consumed by LuaSnip's VSCode loader. Keep it
  # separate from vim-snippets because both formats are loaded.
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.friendly-snippets ];
}
