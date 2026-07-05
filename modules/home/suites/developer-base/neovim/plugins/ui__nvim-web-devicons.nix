{ pkgs, ... }:

{
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.nvim-web-devicons ];
}
