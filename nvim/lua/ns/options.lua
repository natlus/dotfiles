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
vim.o.cmdheight = 0
vim.o.ignorecase = true
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true

vim.opt.exrc = true

-- Skip the :trust prompt for exrc files under these roots (e.g. new worktrees).
local trusted_roots = {
	vim.fn.expand("~/code"),
	vim.fn.expand("~/.local/share/opencode/worktree"),
}
local secure_read = vim.secure.read
---@diagnostic disable-next-line: duplicate-set-field
vim.secure.read = function(path)
	local fullpath = vim.uv.fs_realpath(vim.fs.normalize(path))
	if fullpath and vim.fn.isdirectory(fullpath) == 0 then
		for _, root in ipairs(trusted_roots) do
			if vim.startswith(fullpath, root .. "/") then
				local f = io.open(fullpath, "r")
				if f then
					local contents = f:read("*a")
					f:close()
					return contents
				end
			end
		end
	end
	return secure_read(path)
end

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
