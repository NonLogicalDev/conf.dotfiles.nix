{ lib, pkgs, ... }:

{
  # Dash.app/docset integration for local API lookup on macOS. It is harmless on
  # other systems at evaluation time, but the integration itself expects the
  # macOS Dash.app workflow.
  programs.nixvim.extraPlugins = lib.mkIf pkgs.stdenv.isDarwin [ pkgs.vimPlugins.dash-vim ];
}
