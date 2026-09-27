{ ... }:

{
  # Keep the system Vim fallback useful when Neovim is unavailable. The main
  # editor remains the shared Neovim module; this file does not install Vim.
  home.file.".vimrc".source = ./vimrc;
}
