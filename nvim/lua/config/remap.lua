local map = vim.keymap.set

vim.g.mapleader = " "
vim.g.maplocalleader = " "

map("n", "<leader>sv", vim.cmd.Ex)
map("n", "<leader>w", ":write<CR>", { desc = "[W]rite" })
map({ "n", "v" }, "<leader>o", ":update<CR> :source<CR>", { desc = "source current" })

-- paste/del selection without saving the selection to a register
map("x", "<leader>p", [["_dP]])
map({ "n", "v" }, "<leader>d", [["_d]])

-- clear search highlight on esc
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

map("n", "do", "<cmd>:Gitsigns preview_hunk_inline<CR>", { desc = "Preview diff hunk" })
map("n", "dp", "<cmd>:Gitsigns reset_hunk<CR>", { desc = "Reset diff hunk" })

map("n", "[d", function()
	vim.diagnostic.get_prev()
end)
map("n", "]d", function()
	vim.diagnostic.get_next()
end)
map("n", "gh", function()
	vim.diagnostic.open_float()
end)
