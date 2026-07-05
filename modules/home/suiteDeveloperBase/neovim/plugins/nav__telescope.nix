{
  programs.nixvim.plugins.telescope = {
    # Telescope is the main fuzzy navigation surface: files, grep, buffers,
    # jumplist, and LSP references/definitions.
    enable = true;

    extensions = {
      fzf-native.enable = true;
      frecency.enable = true;
    };

    settings = {
      # Ivy keeps the picker compact at the bottom of the screen, matching the
      # old preference for search surfaces that do not cover the whole editor.
      defaults.__raw = "require('telescope.themes').get_ivy()";
      pickers = {
        live_grep = {
          file_ignore_patterns = [
            "node_modules"
            ".git"
            ".venv"
          ];
          additional_args.__raw = ''
            function()
              return { "--hidden" }
            end
          '';
        };
        find_files = {
          file_ignore_patterns = [
            "node_modules"
            ".git"
            ".venv"
          ];
          hidden = true;
        };
      };
    };

    keymaps = {
      "<leader>ff" = {
        action = "find_files";
        options.desc = "Find files";
      };
      "<leader>fg" = {
        action = "live_grep";
        options.desc = "Live grep";
      };
      "<leader>fw" = {
        action = "grep_string";
        options.desc = "Grep word";
      };
      "<leader>fb" = {
        action = "buffers";
        options.desc = "Buffers";
      };
      "<leader>fj" = {
        action = "jumplist";
        options.desc = "Jumplist";
      };
      "<leader>fr" = {
        action = "lsp_references";
        options.desc = "LSP references";
      };
      "<leader>fd" = {
        action = "lsp_definitions";
        options.desc = "LSP definitions";
      };
      "<leader>fT" = {
        action = "builtin";
        options.desc = "Telescope builtin";
      };
    };
  };
}
