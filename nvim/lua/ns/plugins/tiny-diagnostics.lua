return {
	"rachartier/tiny-inline-diagnostic.nvim",
	event = "VeryLazy",
	priority = 1000,
	config = function()
		require("tiny-inline-diagnostic").setup({
			preset = "simple",
			options = {
				show_all_diags_on_cursorline = false,
				show_code = false,
				enable_on_insert = true,
				add_messages = {
					messages = true,
					display_count = false,
					use_max_severity = true,
					show_multiple_glyphs = true,
				},
				multilines = {
					enabled = true,
				},
				show_related = {
					enabled = false,
				},
				severity = {
					vim.diagnostic.severity.ERROR,
					vim.diagnostic.severity.WARN,
					vim.diagnostic.severity.INFO,
				},

				format = function(diag)
					local msg = tostring(diag.message):gsub("\n.*", "")
					return msg
				end,
			},
		})
		vim.diagnostic.config({ virtual_text = false }) -- Disable Neovim's default virtual text diagnostics
	end,
}
