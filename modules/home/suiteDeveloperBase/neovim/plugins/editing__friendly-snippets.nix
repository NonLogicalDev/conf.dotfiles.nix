{ pkgs, ... }:

{
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.friendly-snippets ];
}
