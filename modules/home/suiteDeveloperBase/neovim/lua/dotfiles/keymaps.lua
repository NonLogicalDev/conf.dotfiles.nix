local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

keymap("n", "tn", ":tabnext<CR>", opts)
keymap("n", "tp", ":tabprev<CR>", opts)
keymap("n", "te", ":tabedit<CR>", opts)
keymap("n", "to", ":tabonly<CR>", opts)
keymap("n", "<C-w><Tab>", ":tabnext<CR>", opts)
keymap("n", "<C-w><S-Tab>", ":tabprev<CR>", opts)

for i = 1, 9 do
  keymap("n", "<C-w>" .. i, i .. "gt", opts)
end

keymap("n", "<leader>v", "`[v`]", opts)
keymap("n", "<leader>V", "`[V`]", opts)
keymap("n", "vgA", "ggVG", opts)
keymap("n", "<leader><leader>m", ":cd %:p:h<CR>:pwd<CR>", opts)

keymap("n", "<leader>'", function()
  vim.opt.hlsearch = not vim.opt.hlsearch:get()
end, opts)
keymap("n", "<leader><leader>`", ":set nohlsearch<CR>", opts)
keymap("n", "n", ":set hlsearch<CR>n", opts)
keymap("n", "N", ":set hlsearch<CR>N", opts)

keymap("n", "<CR>", function()
  if vim.opt.hlsearch:get() then
    vim.opt.hlsearch = false
    return ""
  end
  return "<CR>"
end, { expr = true })

keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

keymap("t", "<C-\\><C-[>", "<C-\\><C-n>", opts)
keymap("t", "<C-\\><C-]>", "<C-\\><C-n>pi", opts)
keymap("n", "Q", "<nop>", opts)
keymap("v", "<", "<gv", opts)
keymap("i", "<C-j>", "<CR><C-o>O", opts)

vim.api.nvim_create_user_command("W", "w", {})

local function toggle_list(bufname, prefix)
  local buflist = vim.fn.execute("ls")
  local matching = vim.fn.filter(vim.fn.split(buflist, "\n"), 'v:val =~ "' .. bufname .. '"')
  for _, line in ipairs(matching) do
    local bufnum = tonumber(vim.fn.matchstr(line, "\\d\\+"))
    if bufnum and vim.fn.bufwinnr(bufnum) ~= -1 then
      vim.cmd(prefix .. "close")
      return
    end
  end

  if prefix == "l" and #vim.fn.getloclist(0) == 0 then
    vim.api.nvim_echo({ { "Location List is Empty.", "ErrorMsg" } }, true, {})
    return
  end

  local winnr = vim.fn.winnr()
  vim.cmd("botright " .. prefix .. "window")
  if vim.fn.winnr() ~= winnr then
    vim.cmd("wincmd p")
  end
end

keymap("n", "<leader><leader>q", function()
  toggle_list("Quickfix List", "c")
end, opts)
keymap("n", "<leader><leader>Q", function()
  toggle_list("Quickfix List", "c")
end, opts)
