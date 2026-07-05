vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.o.exrc = true
vim.o.secure = true
vim.opt.termguicolors = true

vim.g.user_colorway = "catppuccin-mocha"
vim.g.user_colorway_lualine = "auto"

require("dotfiles.options")
require("dotfiles.keymaps")
require("dotfiles.autocmds")
require("dotfiles.completion")
require("dotfiles.lsp")
require("dotfiles.plugins")
