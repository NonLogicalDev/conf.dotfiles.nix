{ pkgs, ... }:

{
  # Delete buffers without destroying the window layout. Kept as an extra
  # plugin because NixVim does not currently expose a dedicated option module.
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.nvim-bufdel ];
}
