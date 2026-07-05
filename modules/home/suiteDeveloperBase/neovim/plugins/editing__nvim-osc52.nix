{ pkgs, ... }:

{
  programs.nixvim = {
    # OSC52 yanking makes clipboard copy work through SSH/tmux/terminal sessions
    # where a native GUI clipboard provider is unavailable.
    extraPlugins = with pkgs.vimPlugins; [
      nvim-osc52
      vim-oscyank
    ];

    extraConfigLua = ''
      vim.api.nvim_create_autocmd("TextYankPost", {
        group = vim.api.nvim_create_augroup("OscYank", { clear = true }),
        callback = function()
          if vim.v.event.operator == "y" and vim.fn.has("clipboard") == 0 and vim.fn.exists("*OSCYankRegister") == 1 then
            vim.fn.OSCYankRegister('"')
          end
        end,
      })
    '';

    keymaps = [
      # Explicit OSC52 mappings are kept even with the TextYankPost autocmd so
      # there is a manual escape hatch when automatic clipboard detection fails.
      {
        mode = "v";
        key = "<leader>c";
        action = "<Plug>OSCYankVisual";
        options.desc = "Yank to system clipboard through OSC52";
      }
      {
        mode = "n";
        key = "<leader>o";
        action = "<Plug>OSCYank";
        options.desc = "Yank to system clipboard through OSC52";
      }
    ];
  };
}
