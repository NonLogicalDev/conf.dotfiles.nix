{ pkgs, ... }:

{
  # Text objects based on indentation blocks. Useful in Python/YAML/Nix-like
  # structured text where braces are not the main unit of movement.
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.vim-indent-object ];
}
