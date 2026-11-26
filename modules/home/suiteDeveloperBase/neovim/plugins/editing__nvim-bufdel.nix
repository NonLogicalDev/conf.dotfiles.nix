{ pkgs, ... }:

{
  # Delete buffers without destroying the window layout. Kept as an extra
  # plugin because NixVim does not currently expose a dedicated option module.
  programs.nixvim = {
    extraPlugins = [ pkgs.vimPlugins.nvim-bufdel ];

    extraConfigLuaPost = ''
      require("bufdel").setup({})
    '';

    # Preserve the short buffer commands from the personal editor profile.
    # BD and BUN pass through an optional bang; BW always forces deletion.
    userCommands = {
      BD = {
        bang = true;
        nargs = "*";
        command.__raw = ''
          function(opts)
            vim.cmd((opts.bang and "BufDel!" or "BufDel") .. " " .. opts.args)
          end
        '';
      };

      BUN = {
        bang = true;
        nargs = "*";
        command.__raw = ''
          function(opts)
            vim.cmd((opts.bang and "BufDel!" or "BufDel") .. " " .. opts.args)
          end
        '';
      };

      BW = {
        nargs = "*";
        command.__raw = ''
          function(opts)
            vim.cmd("BufDel! " .. opts.args)
          end
        '';
      };
    };
  };
}
