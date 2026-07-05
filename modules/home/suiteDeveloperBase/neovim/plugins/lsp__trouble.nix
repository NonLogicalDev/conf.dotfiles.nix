{
  programs.nixvim = {
    plugins.trouble.enable = true;

    keymaps = [
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<cr>";
        options.desc = "Diagnostics";
      }
      {
        mode = "n";
        key = "<leader>xX";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
        options.desc = "Buffer diagnostics";
      }
      {
        mode = "n";
        key = "<leader>cs";
        action = "<cmd>Trouble symbols toggle focus=false<cr>";
        options.desc = "Symbols";
      }
      {
        mode = "n";
        key = "<leader>cl";
        action = "<cmd>Trouble lsp toggle focus=false win.position=right<cr>";
        options.desc = "LSP trouble";
      }
      {
        mode = "n";
        key = "<leader>xL";
        action = "<cmd>Trouble loclist toggle<cr>";
        options.desc = "Location list";
      }
      {
        mode = "n";
        key = "<leader>xQ";
        action = "<cmd>Trouble qflist toggle<cr>";
        options.desc = "Quickfix list";
      }
    ];
  };
}
