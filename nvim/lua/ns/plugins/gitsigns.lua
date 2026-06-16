return {
	"lewis6991/gitsigns.nvim",
	opts = {
		signs = {
			add = { text = "▌" },
			change = { text = "▌" },
			delete = { text = "󰍟" },
			topdelete = { text = "󰍟" },
			changedelete = { text = "~" },
			untracked = { text = "┆" },
		},
		signs_staged_enable = false,
		current_line_blame = true,
		current_line_blame_opts = {
			delay = 0,
		},
		current_line_blame_formatter_nc = "",
		current_line_blame_formatter = "     <author>, <author_time:%R>",
	},
}
