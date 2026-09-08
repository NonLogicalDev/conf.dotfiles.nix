{
  programs.nixvim = {
    # LuaSnip is the snippet engine used by nvim-cmp. It loads both VSCode and
    # snipmate snippet collections because the old config used snippets from
    # both ecosystems.
    plugins.luasnip = {
      enable = true;
      settings = {
        history = true;
        updateevents = "TextChanged,TextChangedI";
        enable_autosnippets = true;
        ext_opts."types.choiceNode".active.virt_text = [
          [
            "●"
            "GruvboxOrange"
          ]
        ];
      };
      fromVscode = [ { } ];
      fromSnipmate = [ { } ];
    };

    keymaps = [
      # Keep snippet navigation explicit on Ctrl-j/k/l so Tab can remain shared
      # with completion fallback logic in the cmp module.
      {
        mode = [
          "i"
          "s"
        ];
        key = "<C-k>";
        action.__raw = ''
          function()
            local luasnip = require("luasnip")
            if luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            end
          end
        '';
        options = {
          silent = true;
          desc = "Expand or jump forward in snippet";
        };
      }
      {
        mode = [
          "i"
          "s"
        ];
        key = "<C-j>";
        action.__raw = ''
          function()
            local luasnip = require("luasnip")
            if luasnip.jumpable(-1) then
              luasnip.jump(-1)
            end
          end
        '';
        options = {
          silent = true;
          desc = "Jump backward in snippet";
        };
      }
      {
        mode = "i";
        key = "<C-l>";
        action.__raw = ''
          function()
            local luasnip = require("luasnip")
            if luasnip.choice_active() then
              luasnip.change_choice(1)
            end
          end
        '';
        options = {
          silent = true;
          desc = "Cycle through snippet choices";
        };
      }
    ];
  };
}
