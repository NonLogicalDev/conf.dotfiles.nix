local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

augroup("KeymapReady", { clear = true })
autocmd("VimEnter", {
  group = "KeymapReady",
  pattern = "*",
  callback = function()
    vim.api.nvim_exec_autocmds("User", { pattern = "KeymapReady" })
    vim.keymap.set("n", "K", "<nop>", { noremap = true, silent = true })
  end,
})

augroup("RestoreCursor", { clear = true })
autocmd("BufReadPost", {
  group = "RestoreCursor",
  pattern = "*",
  callback = function()
    if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line("$") then
      vim.cmd([[normal! g`"]])
    end
  end,
})

augroup("PythonHighlight", { clear = true })
autocmd("FileType", {
  group = "PythonHighlight",
  pattern = "python",
  command = [[syn match pythonBoolean "\(\W\|^\)\@<=self\(\.\)\@="]],
})

augroup("FileTypeSettings", { clear = true })
autocmd("FileType", {
  group = "FileTypeSettings",
  pattern = "markdown",
  callback = function()
    vim.opt_local.foldenable = true
  end,
})

autocmd("BufRead", {
  pattern = "*.stgit-edit.txt",
  command = "setlocal filetype=gitcommit",
})

autocmd("BufRead", {
  pattern = "*.stgit-edit.patch",
  command = "setlocal filetype=gitcommit",
})

autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "@lsp.type.class", { fg = "Aqua" })
    vim.api.nvim_set_hl(0, "@lsp.type.function", { fg = "Yellow" })
    vim.api.nvim_set_hl(0, "@lsp.type.method", { fg = "Green" })
    vim.api.nvim_set_hl(0, "@lsp.type.parameter", { fg = "Purple" })
    vim.api.nvim_set_hl(0, "@lsp.type.variable", { fg = "Blue" })
    vim.api.nvim_set_hl(0, "@lsp.type.property", { fg = "Green" })
  end,
})

vim.api.nvim_create_user_command("RG", function(opts)
  local args = opts.args
  if args == "" then
    vim.notify("RG: No search pattern provided", vim.log.levels.ERROR)
    return
  end

  local output = vim.fn.systemlist("rg --vimgrep --no-heading --smart-case " .. args)
  if vim.v.shell_error ~= 0 and #output == 0 then
    vim.notify("RG: No matches found", vim.log.levels.WARN)
    return
  end

  vim.fn.setqflist({}, "r", {
    title = "RG: " .. args,
    lines = output,
  })
  vim.cmd("copen")
end, {
  nargs = "+",
  complete = "file",
  desc = "Search with ripgrep and populate quickfix",
})

vim.api.nvim_create_user_command("FD", function(opts)
  local args = opts.args
  if args == "" then
    vim.notify("FD: No pattern provided", vim.log.levels.ERROR)
    return
  end

  local output = vim.fn.systemlist("fd " .. args)
  if vim.v.shell_error ~= 0 and #output == 0 then
    vim.notify("FD: No matches found", vim.log.levels.WARN)
    return
  end

  local qf_list = {}
  for _, file in ipairs(output) do
    table.insert(qf_list, {
      filename = file,
      lnum = 1,
      text = file,
    })
  end

  vim.fn.setqflist({}, "r", {
    title = "FD: " .. args,
    items = qf_list,
  })
  vim.cmd("copen")
end, {
  nargs = "+",
  complete = "file",
  desc = "Find files with fd and populate quickfix",
})
