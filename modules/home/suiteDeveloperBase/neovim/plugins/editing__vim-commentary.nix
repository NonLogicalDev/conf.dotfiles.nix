{ pkgs, ... }:

{
  # Minimal comment toggling. Kept instead of a larger commenting plugin because
  # the workflow only needs the classic `gcc`/visual-comment behavior.
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.vim-commentary ];
}
