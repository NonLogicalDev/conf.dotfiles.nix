{ pkgs, ... }:

{
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.targets-vim ];
}
