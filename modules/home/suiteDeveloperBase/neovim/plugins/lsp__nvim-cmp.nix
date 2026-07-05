{
  programs.nixvim.plugins = {
    # Completion is intentionally conservative: LSP + snippets first, buffer as
    # a fallback. Extra sources can be added later when there is a concrete need
    # rather than recreating the old plugin-manager sprawl.
    cmp = {
      enable = true;
      autoEnableSources = false;

      settings = {
        snippet.expand.__raw = ''
          function(args)
            require("luasnip").lsp_expand(args.body)
          end
        '';

        window = {
          completion.__raw = "cmp.config.window.bordered()";
          documentation.__raw = "cmp.config.window.bordered()";
        };

        mapping.__raw = ''
          cmp.mapping.preset.insert({
            ["<C-b>"] = cmp.mapping.scroll_docs(-4),
            ["<C-f>"] = cmp.mapping.scroll_docs(4),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.abort(),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif require("luasnip").expand_or_jumpable() then
                require("luasnip").expand_or_jump()
              else
                fallback()
              end
            end, { "i", "s" }),
            ["<S-Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif require("luasnip").jumpable(-1) then
                require("luasnip").jump(-1)
              else
                fallback()
              end
            end, { "i", "s" }),
          })
        '';

        sources.__raw = ''
          cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "luasnip" },
          }, {
            { name = "buffer" },
          })
        '';
      };

      # Command-line completion mirrors normal mode search/command workflows:
      # buffer words for / and ?, path/cmdline for :.
      cmdline = {
        "/" = {
          mapping.__raw = "cmp.mapping.preset.cmdline()";
          sources = [ { name = "buffer"; } ];
        };

        "?" = {
          mapping.__raw = "cmp.mapping.preset.cmdline()";
          sources = [ { name = "buffer"; } ];
        };

        ":" = {
          mapping.__raw = "cmp.mapping.preset.cmdline()";
          sources.__raw = ''
            cmp.config.sources({
              { name = "path" },
            }, {
              { name = "cmdline" },
            })
          '';
        };
      };

      filetype.gitcommit.sources = [ { name = "buffer"; } ];
    };

    # Source plugins are enabled explicitly so future readers can see exactly
    # where each completion source comes from.
    cmp-buffer.enable = true;
    cmp-cmdline.enable = true;
    cmp-nvim-lsp.enable = true;
    cmp-path.enable = true;
    cmp_luasnip.enable = true;
  };
}
