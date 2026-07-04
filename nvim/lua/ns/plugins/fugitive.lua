return {
	"tpope/vim-fugitive",
	keys = {
		{ "<leader>G", "<cmd>tab Git<cr>", desc = "Git status tab" },
	},
	config = function()
		vim.api.nvim_create_user_command("G", "tab Git", {})
	end,
}
