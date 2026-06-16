return {
	"echasnovski/mini.nvim",
	config = function()
		require("mini.ai").setup({ n_lines = 500 })
		require("mini.surround").setup({
			mappings = {
				add = "sa",
				delete = "ds",
				find = "fs",
				replace = "rs",
			},
		})
		require("mini.move").setup({
			mappings = {
				down = "J",
				up = "K",
			},
		})
		require("mini.pairs").setup()
		require("mini.cmdline").setup()

		local statusline = require("mini.statusline")
		statusline.setup({
			use_icons = false,
		})

		---@diagnostic disable-next-line: duplicate-set-field
		statusline.section_location = function()
			return "%2l:%-2v"
		end
	end,
}
