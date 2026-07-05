pcall(function()
  require("nvim-autopairs").setup({})
end)

pcall(function()
  require("catppuccin").setup({})
end)
pcall(function()
  require("gruvbox").setup({})
end)
pcall(function()
  require("tokyonight").setup({})
end)
pcall(function()
  require("ayu").setup({})
end)

pcall(vim.cmd.colorscheme, vim.g.user_colorway)

pcall(function()
  require("lualine").setup({
    options = {
      theme = vim.g.user_colorway_lualine,
      icons_enabled = false,
      component_separators = "",
      section_separators = "",
    },
  })
end)

pcall(function()
  require("bufferline").setup({
    options = {
      indicator = {
        icon = "|",
        style = "icon",
      },
      buffer_close_icon = "x",
      modified_icon = "*",
      close_icon = "x",
      left_trunc_marker = "<",
      right_trunc_marker = ">",
      separator_style = "thin",
      show_buffer_icons = true,
      show_buffer_close_icons = true,
      show_close_icon = true,
      diagnostics = "nvim_lsp",
      diagnostics_indicator = function(count, level)
        local icon = level:match("error") and "E " or "W "
        return " " .. icon .. count
      end,
    },
  })
end)

pcall(function()
  require("fidget").setup({})
end)

pcall(function()
  require("nvim-tree").setup({
    disable_netrw = false,
    hijack_netrw = true,
    renderer = {
      indent_markers = {
        enable = true,
        inline_arrows = true,
      },
      icons = {
        show = {
          file = false,
          folder = false,
          folder_arrow = true,
          git = true,
        },
      },
    },
    filters = {
      dotfiles = false,
    },
  })

  vim.keymap.set("n", "<leader>n", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file explorer" })
  vim.keymap.set("n", "<leader>m", function()
    require("nvim-tree.api").tree.change_root(vim.fn.getcwd())
  end, { desc = "Update nvim-tree CWD to global CWD" })
end)

pcall(function()
  local telescope = require("telescope")
  local themes = require("telescope.themes")

  telescope.setup({
    defaults = themes.get_ivy(),
    pickers = {
      live_grep = {
        file_ignore_patterns = { "node_modules", ".git", ".venv" },
        additional_args = function()
          return { "--hidden" }
        end,
      },
      find_files = {
        file_ignore_patterns = { "node_modules", ".git", ".venv" },
        hidden = true,
      },
    },
  })

  pcall(telescope.load_extension, "fzf")
  pcall(telescope.load_extension, "frecency")

  local map = vim.keymap.set
  map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
  map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
  map("n", "<leader>fw", "<cmd>Telescope grep_string<cr>", { desc = "Grep word" })
  map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
  map("n", "<leader>fj", "<cmd>Telescope jumplist<cr>", { desc = "Jumplist" })
  map("n", "<leader>fr", "<cmd>Telescope lsp_references<cr>", { desc = "LSP references" })
  map("n", "<leader>fd", "<cmd>Telescope lsp_definitions<cr>", { desc = "LSP definitions" })
  map("n", "<leader>fT", "<cmd>Telescope builtin<cr>", { desc = "Telescope builtin" })
end)

pcall(function()
  require("flash").setup({})
  vim.keymap.set({ "n", "x", "o" }, "s", function()
    require("flash").jump()
  end, { desc = "Flash" })
end)

pcall(function()
  require("trouble").setup({})
  vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics" })
  vim.keymap.set("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer diagnostics" })
  vim.keymap.set("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols" })
  vim.keymap.set("n", "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", { desc = "LSP trouble" })
  vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location list" })
  vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix list" })
end)

pcall(function()
  require("toggleterm").setup({
    size = function(term)
      if term.direction == "horizontal" then
        return 15
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.5
      end
    end,
    open_mapping = [[<c-=>]],
    hide_numbers = true,
    shade_terminals = true,
    shading_factor = 2,
    start_in_insert = true,
    insert_mappings = true,
    terminal_mappings = true,
    persist_size = true,
    persist_mode = true,
    direction = "float",
    close_on_exit = true,
    shell = vim.o.shell,
    auto_scroll = true,
    float_opts = {
      border = "curved",
      width = function()
        return math.floor(vim.o.columns * 0.8)
      end,
      height = function()
        return math.floor(vim.o.lines * 0.8)
      end,
      winblend = 0,
    },
  })

  vim.keymap.set("n", "<leader>tt", "<cmd>ToggleTerm direction=float<cr>", { desc = "Toggle floating terminal" })
  vim.keymap.set("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", { desc = "Toggle horizontal terminal" })
  vim.keymap.set("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", { desc = "Toggle vertical terminal" })
end)

pcall(function()
  require("gitsigns").setup({
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns
      local function map(mode, lhs, rhs, options)
        options = options or {}
        options.buffer = bufnr
        vim.keymap.set(mode, lhs, rhs, options)
      end

      map("n", "]c", function()
        if vim.wo.diff then
          return "]c"
        end
        vim.schedule(function()
          gs.next_hunk()
        end)
        return "<Ignore>"
      end, { expr = true })

      map("n", "[c", function()
        if vim.wo.diff then
          return "[c"
        end
        vim.schedule(function()
          gs.prev_hunk()
        end)
        return "<Ignore>"
      end, { expr = true })

      map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
      map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
      map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
      map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
      map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
      map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
      map("n", "<leader>hb", function()
        gs.blame_line({ full = true })
      end, { desc = "Blame line" })
      map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "Toggle blame" })
      map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
    end,
  })
end)

vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    if pcall(vim.treesitter.start) then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("OscYank", { clear = true }),
  callback = function()
    if vim.v.event.operator == "y" and vim.fn.has("clipboard") == 0 and vim.fn.exists("*OSCYankRegister") == 1 then
      vim.fn.OSCYankRegister('"')
    end
  end,
})

vim.keymap.set("v", "<leader>c", "<Plug>OSCYankVisual", { desc = "Yank to system clipboard through OSC52" })
vim.keymap.set("n", "<leader>o", "<Plug>OSCYank", { desc = "Yank to system clipboard through OSC52" })
