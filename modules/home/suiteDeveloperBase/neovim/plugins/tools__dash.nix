{ pkgs, ... }:

{
  # Dash.app/docset integration for local API lookup on macOS. It is harmless on
  # other systems but mostly valuable on Darwin developer machines.
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.dash-vim ];
}
