vim.cmd([[set noswapfile]])
vim.g.have_nerd_font = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.wrap = true

vim.o.number = true
vim.o.relativenumber = true
vim.opt.signcolumn = "yes"

vim.o.mouse = "a"
vim.o.showmode = false
vim.o.ignorecase = true
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true

vim.opt.exrc = true

-- Use OS clipboard.
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking text",
	group = vim.api.nvim_create_augroup("ns-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})
