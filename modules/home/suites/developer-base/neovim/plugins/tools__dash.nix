{ pkgs, ... }:

{
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.dash-vim ];
}
