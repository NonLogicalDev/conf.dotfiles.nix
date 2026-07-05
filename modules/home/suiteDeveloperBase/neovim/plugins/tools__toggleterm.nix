{
  programs.nixvim = {
    # Embedded terminals are for quick project commands without leaving Neovim.
    # The default is a floating terminal; horizontal/vertical variants stay on
    # leader mappings for when output needs to remain visible.
    plugins.toggleterm = {
      enable = true;
      settings = {
        size = ''
          function(term)
            if term.direction == "horizontal" then
              return 15
            elseif term.direction == "vertical" then
              return vim.o.columns * 0.5
            end
          end
        '';
        open_mapping = "[[<c-=>]]";
        hide_numbers = true;
        shade_terminals = true;
        shading_factor = 2;
        start_in_insert = true;
        insert_mappings = true;
        terminal_mappings = true;
        persist_size = true;
        persist_mode = true;
        direction = "float";
        close_on_exit = true;
        shell.__raw = "vim.o.shell";
        auto_scroll = true;
        float_opts = {
          border = "curved";
          width = ''
            function()
              return math.floor(vim.o.columns * 0.8)
            end
          '';
          height = ''
            function()
              return math.floor(vim.o.lines * 0.8)
            end
          '';
          winblend = 0;
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>tt";
        action = "<cmd>ToggleTerm direction=float<cr>";
        options.desc = "Toggle floating terminal";
      }
      {
        mode = "n";
        key = "<leader>th";
        action = "<cmd>ToggleTerm direction=horizontal<cr>";
        options.desc = "Toggle horizontal terminal";
      }
      {
        mode = "n";
        key = "<leader>tv";
        action = "<cmd>ToggleTerm direction=vertical<cr>";
        options.desc = "Toggle vertical terminal";
      }
    ];
  };
}
