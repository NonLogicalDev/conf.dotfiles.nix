{ pkgs, ... }:

{
  programs.nixvim = {
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
