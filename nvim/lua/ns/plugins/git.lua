-- Git setup modelled on craftzdog's: gitsigns + mini.diff overlay (in editor.lua) + codediff.
return {
	{
		"lewis6991/gitsigns.nvim",
		lazy = false, -- keys would otherwise lazy-load it, hiding signs until first use
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
		},
		config = function(_, opts)
			require("gitsigns").setup(opts)
			-- match mini.diff's line-number colors
			for _, kind in ipairs({ "Add", "Change", "Delete" }) do
				vim.api.nvim_set_hl(0, "GitSigns" .. kind, { link = "MiniDiffSign" .. kind })
			end
		end,
		keys = {
			{ "do", "<cmd>Gitsigns preview_hunk_inline<cr>", desc = "Preview diff hunk" },
			{ "dp", "<cmd>Gitsigns reset_hunk<cr>", desc = "Reset diff hunk" },
			{
				"<leader>gb",
				function()
					require("gitsigns").blame_line()
				end,
				desc = "Blame current line",
			},
			{
				"<leader>gB",
				function()
					require("gitsigns").blame()
				end,
				desc = "Blame buffer",
			},
			{
				"<leader>gs",
				function()
					local gs = require("gitsigns")
					if #(gs.get_hunks() or {}) > 0 then
						gs.stage_buffer()
					else
						gs.reset_buffer_index()
					end
				end,
				desc = "Toggle stage buffer",
			},
			{
				"<leader>gh",
				function()
					require("gitsigns").stage_hunk()
				end,
				desc = "Toggle stage hunk",
			},
			{
				"<leader>gr",
				function()
					require("gitsigns").reset_hunk()
				end,
				desc = "Reset hunk",
			},
			{
				"<leader>gd",
				function()
					require("mini.diff").toggle_overlay()
				end,
				desc = "Toggle MiniDiff overlay",
			},
		},
	},

	{
		"esmuellert/codediff.nvim",
		cmd = "CodeDiff",
		opts = {
			explorer = {
				width = 50,
				auto_open_on_cursor = true,
				view_mode = "tree",
				line_stats = { enabled = true },
			},
			diff = {
				compact = true,
				compact_context_lines = 8,
				compact_sync_folds = true,
			},
		},
		keys = {
			-- craftzdog uses <leader>d*, which clashes with our "_d mapping
			{ "<leader>gv", "<cmd>CodeDiff<cr>", desc = "Toggle CodeDiff" },
			{ "<leader>gf", "<cmd>CodeDiff history %<cr>", desc = "File history (current file)" },
			{ "<leader>gF", "<cmd>CodeDiff history<cr>", desc = "File history (repo)" },
		},
	},

	{ "akinsho/git-conflict.nvim", version = "*", config = true },
}
