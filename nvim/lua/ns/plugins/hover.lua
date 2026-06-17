return {
	"lewis6991/hover.nvim",
	config = function()
		require("hover").config({
			providers = {
				"hover.providers.diagnostic",
				"hover.providers.lsp",
				"hover.providers.man",
				"hover.providers.dictionary",
			},
			preview_opts = {
				border = "rounded",
			},
			title = true,
		})

		vim.keymap.set("n", "K", function()
			require("hover").open()
		end, { desc = "Hover" })

		vim.keymap.set("n", "gK", function()
			require("hover").enter()
		end, { desc = "Enter hover" })

		vim.keymap.set("n", "<C-p>", function()
			require("hover").switch("previous")
		end, { desc = "Previous hover source" })

		vim.keymap.set("n", "<C-n>", function()
			require("hover").switch("next")
		end, { desc = "Next hover source" })
	end,
}
