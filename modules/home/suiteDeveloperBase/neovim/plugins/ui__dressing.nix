{ pkgs, ... }:

{
  # Use the editor's existing select/input UI integration when a plugin asks.
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.dressing-nvim ];
}
