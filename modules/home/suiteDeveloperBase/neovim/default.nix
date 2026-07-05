{
  inputs,
  pkgs,
  ...
}:

{
  # This is the NixVim composition root. Plugin modules are grouped by the same
  # namespace idea as the old Neovim config, but each file now owns one plugin
  # or one tight plugin family through typed Nix options instead of Lua package
  # manager declarations.
  imports = [
    inputs.nixvim.homeModules.nixvim

    ./plugins/editing__friendly-snippets.nix
    ./plugins/editing__luasnip.nix
    ./plugins/editing__nvim-autopairs.nix
    ./plugins/editing__nvim-bufdel.nix
    ./plugins/editing__nvim-osc52.nix
    ./plugins/editing__tabular.nix
    ./plugins/editing__targets.nix
    ./plugins/editing__vim-commentary.nix
    ./plugins/editing__vim-indent-object.nix
    ./plugins/editing__vim-repeat.nix
    ./plugins/editing__vim-snippets.nix
    ./plugins/editing__vim-surround.nix
    ./plugins/lsp__nvim-cmp.nix
    ./plugins/lsp__nvim-lspconfig.nix
    ./plugins/lsp__nvim-treesitter.nix
    ./plugins/lsp__trouble.nix
    ./plugins/nav__flash.nix
    ./plugins/nav__nvim-tree.nix
    ./plugins/nav__telescope.nix
    ./plugins/theme__catppuccin.nix
    ./plugins/tools__dash.nix
    ./plugins/tools__toggleterm.nix
    ./plugins/ui__bufferline.nix
    ./plugins/ui__fidget.nix
    ./plugins/ui__lualine.nix
    ./plugins/ui__nvim-web-devicons.nix
    ./plugins/vcs__gitsigns.nix
  ];

  # Neovim is managed through NixVim, not as a copied Dotter tree or a hand-built
  # Home Manager wrapper. Nix owns the editor package, plugins, language servers,
  # and small CLI tools the config calls from commands such as :RG, :FD, and
  # Telescope live_grep.
  programs.nixvim = {
    enable = true;
    enableMan = false;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;

    # The flake input follows this repo's nixpkgs on purpose. Tell NixVim which
    # source that is so it does not warn about the followed input at evaluation.
    nixpkgs.source = pkgs.path;

    extraPackages = with pkgs; [
      fd
      gopls
      lua-language-server
      ripgrep
      stylua
    ];

    extraConfigLua = builtins.readFile ./init.lua;
  };

  # Companion Lua is grouped by behavior, not by the old Lazy.nvim plugin-file
  # layout. These files are ordinary Neovim config loaded by init.lua. Keep this
  # surface small: plugin-specific setup should move into NixVim plugin modules
  # when NixVim exposes a clean option for it.
  xdg.configFile = {
    "nvim/lua/dotfiles/autocmds.lua".source = ./lua/dotfiles/autocmds.lua;
    "nvim/lua/dotfiles/keymaps.lua".source = ./lua/dotfiles/keymaps.lua;
    "nvim/lua/dotfiles/options.lua".source = ./lua/dotfiles/options.lua;
    "nvim/after/ftplugin/python.vim".source = ./after/ftplugin/python.vim;
  };
}
