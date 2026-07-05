{
  programs.nixvim = {
    # LSP setup lives in NixVim so server packages/settings are visible in Nix
    # review rather than hidden in Lua plugin declarations.
    plugins.lspconfig.enable = true;

    lsp.servers = {
      # Give every server completion capabilities from nvim-cmp unless a server
      # overrides them later.
      "*" = {
        config.capabilities.__raw = "require('cmp_nvim_lsp').default_capabilities()";
      };

      lua_ls = {
        # Lua server is mostly for editing Neovim config itself.
        enable = true;
        config.settings.Lua = {
          diagnostics.globals = [ "vim" ];
          workspace = {
            library.__raw = ''vim.api.nvim_get_runtime_file("", true)'';
            checkThirdParty = false;
          };
        };
      };

      gopls = {
        # Go is a primary development language in this profile, so gopls gets
        # richer codelenses, hints, staticcheck, and unimported completion.
        enable = true;
        config.settings.gopls = {
          gofumpt = true;
          codelenses = {
            gc_details = false;
            generate = true;
            regenerate_cgo = true;
            run_govulncheck = true;
            test = true;
            tidy = true;
            upgrade_dependency = true;
            vendor = true;
          };
          hints = {
            assignVariableTypes = true;
            compositeLiteralFields = true;
            compositeLiteralTypes = true;
            constantValues = true;
            functionTypeParameters = true;
            parameterNames = true;
            rangeVariableTypes = true;
          };
          analyses = {
            nilness = true;
            unusedparams = true;
            unusedwrite = true;
            useany = true;
          };
          usePlaceholders = true;
          completeUnimported = true;
          staticcheck = true;
          directoryFilters = [
            "-.git"
            "-.vscode"
            "-.idea"
            "-.vscode-test"
            "-node_modules"
          ];
          semanticTokens = true;
        };
      };
    };

    extraConfigLua = ''
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)

          vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
          vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
          vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
          vim.keymap.set("n", "<space>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, opts)
          vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
          vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<space>f", function()
            vim.lsp.buf.format({ async = true })
          end, opts)

          if vim.lsp.inlay_hint then
            vim.keymap.set("n", "<space>uh", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
            end, opts)
          end

          if client and client.name == "gopls" and not client.server_capabilities.semanticTokensProvider then
            local semantic = client.config.capabilities and client.config.capabilities.textDocument.semanticTokens
            if semantic then
              client.server_capabilities.semanticTokensProvider = {
                full = true,
                legend = {
                  tokenTypes = semantic.tokenTypes,
                  tokenModifiers = semantic.tokenModifiers,
                },
                range = true,
              }
            end
          end
        end,
      })
    '';
  };
}
