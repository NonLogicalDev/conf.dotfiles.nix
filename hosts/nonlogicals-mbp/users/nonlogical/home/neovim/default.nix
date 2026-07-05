{
  pkgs,
  ...
}:

let
  # Keep the plugin inventory as one Nix value. Home Manager receives it through
  # `programs.neovim.plugins`, and the wrapper also derives a pack directory
  # from the same list so Neovim can find plugin Lua modules at startup.
  plugins = with pkgs.vimPlugins; [
    {
      plugin = nvim-treesitter.withPlugins (
        parsers: with parsers; [
          c
          go
          html
          javascript
          lua
          query
          rust
          typescript
          vim
          vimdoc
          yaml
        ]
      );
    }

    ayu-vim
    bufferline-nvim
    catppuccin-nvim
    cmp-buffer
    cmp-cmdline
    cmp-nvim-lsp
    cmp-path
    cmp_luasnip
    dash-vim
    fidget-nvim
    flash-nvim
    friendly-snippets
    gitsigns-nvim
    gruvbox-nvim
    luasnip
    lualine-nvim
    nvim-autopairs
    nvim-bufdel
    nvim-cmp
    nvim-lspconfig
    nvim-osc52
    nvim-tree-lua
    nvim-web-devicons
    plenary-nvim
    tabular
    targets-vim
    telescope-frecency-nvim
    telescope-fzf-native-nvim
    telescope-nvim
    tokyonight-nvim
    toggleterm-nvim
    trouble-nvim
    vim-commentary
    vim-indent-object
    vim-oscyank
    vim-repeat
    vim-snippets
    vim-surround
  ];

  pluginPackDir = pkgs.vimUtils.packDir {
    hm = {
      start = map (plugin: plugin.plugin or plugin) plugins;
      opt = [ ];
    };
  };
in

{
  # Neovim is managed as a Home Manager program, not as a copied Dotter tree.
  # Nix owns the editor package, plugins, language servers, and small CLI tools
  # the config calls from commands such as :RG, :FD, and Telescope live_grep.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;

    extraPackages = with pkgs; [
      fd
      gopls
      lua-language-server
      ripgrep
      stylua
    ];

    inherit plugins;

    extraWrapperArgs = [
      "--add-flags"
      ''--cmd "set packpath^=${pluginPackDir}"''
      "--add-flags"
      ''--cmd "set runtimepath^=${pluginPackDir}"''
    ];

    initLua = builtins.readFile ./init.lua;
  };

  # Companion Lua is grouped by behavior, not by the old Lazy.nvim plugin-file
  # layout. These files are ordinary Neovim config loaded by init.lua.
  xdg.configFile = {
    "nvim/lua/dotfiles/autocmds.lua".source = ./lua/dotfiles/autocmds.lua;
    "nvim/lua/dotfiles/completion.lua".source = ./lua/dotfiles/completion.lua;
    "nvim/lua/dotfiles/keymaps.lua".source = ./lua/dotfiles/keymaps.lua;
    "nvim/lua/dotfiles/lsp.lua".source = ./lua/dotfiles/lsp.lua;
    "nvim/lua/dotfiles/options.lua".source = ./lua/dotfiles/options.lua;
    "nvim/lua/dotfiles/plugins.lua".source = ./lua/dotfiles/plugins.lua;
    "nvim/after/ftplugin/python.vim".source = ./after/ftplugin/python.vim;
  };
}
