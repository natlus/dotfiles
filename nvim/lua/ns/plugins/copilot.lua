return {
	"zbirenbaum/copilot.lua",
	dependencies = {
		"copilotlsp-nvim/copilot-lsp",
		init = function()
			vim.g.copilot_nes_debounce = 500
		end,
	},
	event = "InsertEnter",
	cmd = "Copilot",
	opts = {
		suggestion = {
			enabled = true,
			auto_trigger = true,
			keymap = {
				accept = "<M-Tab>",
			},
		},
		nes = {
			enabled = false,
		},
	},
}
