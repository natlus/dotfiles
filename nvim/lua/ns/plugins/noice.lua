return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
	opts = {
		cmdline = {
			enabled = false,
		},
		popupmenu = {
			enabled = false,
		},
		messages = {
			enabled = false,
		},
		notify = {
			enabled = false,
		},
		lsp = {
			hover = {
				enabled = true,
			},
			signature = {
				enabled = true,
			},
			documentation = {
				opts = {
					border = "single",
				},
			},
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				["cmp.entry.get_documentation"] = true,
			},
		},
		presets = {
			command_palette = false,
			long_message_to_split = false,
			inc_rename = false,
			lsp_doc_border = true,
		},
	},
}
