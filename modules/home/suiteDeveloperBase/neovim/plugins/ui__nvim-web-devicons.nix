{ pkgs, ... }:

{
  # Icon provider required by some UI plugins even when individual UIs disable
  # most icons. Keeping it explicit avoids mystery plugin dependencies.
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.nvim-web-devicons ];
}
