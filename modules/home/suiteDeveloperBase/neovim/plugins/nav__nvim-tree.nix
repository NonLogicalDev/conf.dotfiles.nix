{
  programs.nixvim = {
    # nvim-tree is the persistent project tree. Telescope owns fuzzy open/search;
    # this owns "show me the project shape and current file context".
    plugins.nvim-tree = {
      enable = true;
      settings = {
        disable_netrw = false;
        # Hijack netrw so directory buffers open in the same file-tree UI.
        hijack_netrw = true;
        renderer = {
          indent_markers = {
            enable = true;
            inline_arrows = true;
          };
          icons.show = {
            file = false;
            folder = false;
            folder_arrow = true;
            git = true;
          };
        };
        filters.dotfiles = false;
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>n";
        action = "<cmd>NvimTreeToggle<cr>";
        options.desc = "Toggle file explorer";
      }
      {
        mode = "n";
        key = "<leader>m";
        action.__raw = ''
          function()
            require("nvim-tree.api").tree.change_root(vim.fn.getcwd())
          end
        '';
        options.desc = "Update nvim-tree CWD to global CWD";
      }
    ];
  };
}
