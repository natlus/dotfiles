vim.cmd([[set noswapfile]])
vim.g.have_nerd_font = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2

vim.o.number = true
vim.o.relativenumber = true

vim.o.mouse = "a"
vim.o.showmode = false
vim.o.ignorecase = true
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true

-- use OS clipboard
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- Highlight when yanking text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

require("config.remap")
require("config.lazy")
