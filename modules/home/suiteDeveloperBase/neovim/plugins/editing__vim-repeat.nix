{ pkgs, ... }:

{
  # Lets plugin-provided operators participate in `.` repeat. This is glue for
  # surround/commentary style editing, not a user-visible feature by itself.
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.vim-repeat ];
}
